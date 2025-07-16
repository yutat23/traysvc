package main

import (
	"embed"
	"io/fs"
)

//go:embed icons/*
var iconFS embed.FS

// アイコンデータをバイナリ配列として格納
var (
	settingsIconData []byte
	redCircleIconData []byte
	greenCircleIconData []byte
)

// アイコンデータを初期化
func initIcons() error {
	var err error
	
	// settings.ico を読み込み
	settingsIconData, err = fs.ReadFile(iconFS, "icons/settings.ico")
	if err != nil {
		return err
	}
	
	// red-circle.ico を読み込み
	redCircleIconData, err = fs.ReadFile(iconFS, "icons/red-circle_bgw.ico")
	if err != nil {
		return err
	}
	
	// green-circle.ico を読み込み
	greenCircleIconData, err = fs.ReadFile(iconFS, "icons/green-circle_bgw.ico")
	if err != nil {
		return err
	}
	
	return nil
}

// メインアイコン（設定アイコン）を取得
func getIcon() []byte {
	return settingsIconData
}

// 実行中アイコン（緑の円）を取得
func getRunningIcon() []byte {
	return greenCircleIconData
}

// 停止中アイコン（赤の円）を取得
func getStoppedIcon() []byte {
	return redCircleIconData
}
