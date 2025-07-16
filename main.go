//go:build windows
// +build windows

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"

	"github.com/getlantern/systray"
	"github.com/go-toast/toast"
	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/mgr"
)

type Config struct {
	PollIntervalSec int `json:"poll_interval_sec"`
	Services        []struct {
		Name        string `json:"name"`
		DisplayName string `json:"display_name"`
	} `json:"services"`
}

type ServiceStatus struct {
	Name        string
	DisplayName string
	Status      svc.State
	Running     bool
}

var (
	config     Config
	services   []ServiceStatus
	statusMenu map[string]*systray.MenuItem
)

func main() {
	// 管理者権限を確認し、必要に応じてUACで権限を求める
	if !isElevated() {
		restartAsElevated()
		return
	}

	// コンソールを非表示にする
	hideConsole()

	// アイコンデータを初期化
	if err := initIcons(); err != nil {
		log.Fatalf("アイコンデータの初期化に失敗: %v", err)
	}

	// 設定ファイルを読み込み
	if err := loadConfig(); err != nil {
		log.Fatalf("設定ファイルの読み込みに失敗: %v", err)
	}

	// サービス情報を初期化
	initializeServices()

	// タスクトレイアイコンを開始
	systray.Run(onReady, onExit)
}

// 管理者権限を確認する関数
func isElevated() bool {
	var sid *windows.SID
	err := windows.AllocateAndInitializeSid(
		&windows.SECURITY_NT_AUTHORITY,
		2,
		windows.SECURITY_BUILTIN_DOMAIN_RID,
		windows.DOMAIN_ALIAS_RID_ADMINS,
		0, 0, 0, 0, 0, 0,
		&sid)
	if err != nil {
		return false
	}
	defer windows.FreeSid(sid)

	token := windows.Token(0)
	member, err := token.IsMember(sid)
	if err != nil {
		return false
	}

	return member
}

// UACで管理者権限を求める関数
func restartAsElevated() {
	verb := "runas"
	exe, _ := os.Executable()
	cwd, _ := os.Getwd()
	args := os.Args[1:]

	verbPtr, _ := syscall.UTF16PtrFromString(verb)
	exePtr, _ := syscall.UTF16PtrFromString(exe)
	cwdPtr, _ := syscall.UTF16PtrFromString(cwd)
	argPtr, _ := syscall.UTF16PtrFromString(strings.Join(args, " "))

	var showCmd int32 = 1 //SW_NORMAL

	err := windows.ShellExecute(0, verbPtr, exePtr, argPtr, cwdPtr, showCmd)
	if err != nil {
		log.Fatalf("管理者権限での再起動に失敗: %v", err)
	}
}

// コンソールを非表示にする関数
func hideConsole() {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	proc := kernel32.NewProc("FreeConsole")
	proc.Call()
}

func loadConfig() error {
	// 実行ファイルのディレクトリを取得
	exePath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("実行ファイルのパス取得に失敗: %v", err)
	}
	
	exeDir := filepath.Dir(exePath)
	configPath := filepath.Join(exeDir, "config.json")
	
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// デフォルト設定を作成
		config = Config{
			PollIntervalSec: 30,
			Services: []struct {
				Name        string `json:"name"`
				DisplayName string `json:"display_name"`
			}{
				{Name: "postgresql-x64-16", DisplayName: "PostgreSQL"},
				{Name: "Everything", DisplayName: "Everything"},
			},
		}
		return nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &config)
}

func initializeServices() {
	services = make([]ServiceStatus, len(config.Services))
	statusMenu = make(map[string]*systray.MenuItem)

	for i, serviceConfig := range config.Services {
		services[i] = ServiceStatus{
			Name:        serviceConfig.Name,
			DisplayName: serviceConfig.DisplayName,
			Status:      svc.Stopped,
			Running:     false,
		}
	}
}

func onReady() {
	// アイコンを設定
	systray.SetIcon(getIcon())
	systray.SetTitle("サービス監視")
	systray.SetTooltip("Windowsサービス監視ツール")

	// メニューを作成
	createMenu()

	// サービス状態を更新
	updateServiceStatus()

	// 定期的にサービス状態を監視
	go monitorServices()
}

func onExit() {
	// クリーンアップ処理
}

func createMenu() {
	// サービス状態メニュー
	for _, service := range services {
		menuItem := systray.AddMenuItem(service.DisplayName, service.DisplayName+"の状態を表示")
		statusMenu[service.Name] = menuItem
	}

	systray.AddSeparator()

	// 操作メニュー
	var startAll, stopAll *systray.MenuItem
	if len(services) > 1 {
		startAll = systray.AddMenuItem("すべて開始", "すべてのサービスを開始")
		stopAll = systray.AddMenuItem("すべて停止", "すべてのサービスを停止")
	}
	refresh := systray.AddMenuItem("更新", "サービス状態を更新")

	systray.AddSeparator()

	// 終了メニュー
	quit := systray.AddMenuItem("終了", "アプリケーションを終了")

	// メニューイベントを処理
	go func() {
		for {
			select {
			case <-refresh.ClickedCh:
				updateServiceStatus()
			case <-quit.ClickedCh:
				systray.Quit()
				return
			}
		}
	}()
	
	// すべて開始・停止メニューのイベント処理（サービスが2つ以上ある場合のみ）
	if startAll != nil {
		go func() {
			for {
				<-startAll.ClickedCh
				if showConfirmDialog("確認", "すべてのサービスを開始しますか？") {
					startAllServices()
				}
			}
		}()
	}
	
	if stopAll != nil {
		go func() {
			for {
				<-stopAll.ClickedCh
				if showConfirmDialog("確認", "すべてのサービスを停止しますか？") {
					stopAllServices()
				}
			}
		}()
	}

	// 個別サービスメニューのイベント処理
	for serviceName, menuItem := range statusMenu {
		go func(name string, item *systray.MenuItem) {
			for {
				<-item.ClickedCh
				toggleService(name)
			}
		}(serviceName, menuItem)
	}
}

func monitorServices() {
	ticker := time.NewTicker(time.Duration(config.PollIntervalSec) * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			updateServiceStatus()
		}
	}
}

func updateServiceStatus() {
	for i := range services {
		status, err := getServiceStatus(services[i].Name)
		if err != nil {
			log.Printf("サービス %s の状態取得エラー: %v", services[i].Name, err)
			continue
		}

		services[i].Status = status
		services[i].Running = (status == svc.Running)

		// メニューアイテムを更新
		if menuItem, exists := statusMenu[services[i].Name]; exists {
			statusText := getStatusText(status)
			menuItem.SetTitle(fmt.Sprintf("%s: %s", services[i].DisplayName, statusText))

			// アイコンを更新
			if services[i].Running {
				menuItem.SetIcon(getRunningIcon())
			} else {
				menuItem.SetIcon(getStoppedIcon())
			}
		}
	}
}

func getServiceStatus(serviceName string) (svc.State, error) {
	m, err := mgr.Connect()
	if err != nil {
		return svc.Stopped, err
	}
	defer m.Disconnect()

	s, err := m.OpenService(serviceName)
	if err != nil {
		return svc.Stopped, err
	}
	defer s.Close()

	status, err := s.Query()
	if err != nil {
		return svc.Stopped, err
	}

	return status.State, nil
}

func getStatusText(status svc.State) string {
	switch status {
	case svc.Running:
		return "実行中"
	case svc.Stopped:
		return "停止中"
	case svc.StartPending:
		return "開始中"
	case svc.StopPending:
		return "停止中"
	default:
		return "不明"
	}
}

func toggleService(serviceName string) {
	status, err := getServiceStatus(serviceName)
	if err != nil {
		showNotification("エラー", fmt.Sprintf("サービス %s の状態取得に失敗しました", serviceName))
		return
	}

	if status == svc.Running {
		stopService(serviceName)
	} else {
		startService(serviceName)
	}
}

func startService(serviceName string) {
	// 管理者権限を再確認
	if !isElevated() {
		showNotification("権限エラー", "管理者権限が必要です。アプリケーションを再起動してください。")
		return
	}

	m, err := mgr.Connect()
	if err != nil {
		showNotification("エラー", "サービスマネージャーに接続できませんでした")
		return
	}
	defer m.Disconnect()

	s, err := m.OpenService(serviceName)
	if err != nil {
		showNotification("エラー", fmt.Sprintf("サービス %s を開けませんでした", serviceName))
		return
	}
	defer s.Close()

	err = s.Start()
	if err != nil {
		showNotification("エラー", fmt.Sprintf("サービス %s の開始に失敗しました", serviceName))
		return
	}

	showNotification("成功", fmt.Sprintf("サービス %s を開始しました", serviceName))
	updateServiceStatus()
}

func stopService(serviceName string) {
	// 管理者権限を再確認
	if !isElevated() {
		showNotification("権限エラー", "管理者権限が必要です。アプリケーションを再起動してください。")
		return
	}

	m, err := mgr.Connect()
	if err != nil {
		showNotification("エラー", "サービスマネージャーに接続できませんでした")
		return
	}
	defer m.Disconnect()

	s, err := m.OpenService(serviceName)
	if err != nil {
		showNotification("エラー", fmt.Sprintf("サービス %s を開けませんでした", serviceName))
		return
	}
	defer s.Close()

	_, err = s.Control(svc.Stop)
	if err != nil {
		showNotification("エラー", fmt.Sprintf("サービス %s の停止に失敗しました", serviceName))
		return
	}

	showNotification("成功", fmt.Sprintf("サービス %s を停止しました", serviceName))
	updateServiceStatus()
}

func startAllServices() {
	for _, service := range services {
		if !service.Running {
			startService(service.Name)
		}
	}
}

func stopAllServices() {
	for _, service := range services {
		if service.Running {
			stopService(service.Name)
		}
	}
}

func showNotification(title, message string) {
	notification := toast.Notification{
		AppID:    "ServiceMonitor",
		Title:    title,
		Message:  message,
		Duration: toast.Short,
	}

	if err := notification.Push(); err != nil {
		log.Printf("通知の送信に失敗: %v", err)
	}
}

// 確認ダイアログを表示する関数
func showConfirmDialog(title, message string) bool {
	user32 := syscall.NewLazyDLL("user32.dll")
	messageBox := user32.NewProc("MessageBoxW")

	titlePtr, _ := syscall.UTF16PtrFromString(title)
	messagePtr, _ := syscall.UTF16PtrFromString(message)

	// MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2
	const (
		MB_YESNO        = 0x00000004
		MB_ICONQUESTION = 0x00000020
		MB_DEFBUTTON2   = 0x00000100
		IDYES           = 6
	)

	ret, _, _ := messageBox.Call(
		0, // hWnd
		uintptr(unsafe.Pointer(messagePtr)),
		uintptr(unsafe.Pointer(titlePtr)),
		uintptr(MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2),
	)

	return ret == IDYES
}


