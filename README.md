# Windowsサービス監視ツール

Windowsサービスの監視とタスクトレイからの操作を行うGoアプリケーションです。

## 機能

- **サービス監視**: 設定されたWindowsサービスの状態を定期的に監視
- **タスクトレイ操作**: タスクトレイアイコンからサービスの開始・停止操作
- **リアルタイム通知**: サービス操作の結果をWindows通知で表示
- **一括操作**: すべてのサービスの一括開始・停止
- **設定可能**: JSONファイルで監視対象サービスとポーリング間隔を設定

## 必要な環境

- Windows 10/11
- Go 1.24以上
- 管理者権限（サービス操作に必要）
- rsrcツール（マニフェスト適用用）

## インストール

### 方法1: インストーラを使用（推奨）

1. リポジトリをクローン
```bash
git clone git@github.com:yutat23/traysvc.git
cd traysvc
```

2. 依存関係をインストール
```bash
go mod tidy
```

3. rsrcツールをインストール（マニフェスト適用用）
```bash
go install github.com/akavel/rsrc@latest
```

4. アプリケーションをビルド

#### 単一アーキテクチャ用ビルド
```bash
# Windowsバッチファイルを使用
build.bat

# またはPowerShellスクリプトを使用
.\build.ps1

# または手動でビルド
go build -ldflags="-H windowsgui -s -w" -o traysvc.exe main.go icon.go
```

#### マルチアーキテクチャ用ビルド
```bash
# AMD64（x64）アーキテクチャ専用
.\build-amd64.ps1

# ARM64アーキテクチャ専用
.\build-arm64.ps1

# 両方のアーキテクチャを一度にビルド
.\build-all.ps1
```

**注意**: マルチアーキテクチャビルドには`rsrc`ツールが必要です：
```bash
go install github.com/akavel/rsrc@latest
```

5. アプリケーションの実行

ビルドが完了すると、`dist`フォルダに以下のファイルが生成されます：
- 実行ファイル（`traysvc-amd64.exe`、`traysvc-arm64.exe`）
- `config.json`（設定ファイル）
- スタートアップ管理batファイル

### 方法2: 手動インストール

1. 上記の手順1-4を実行
2. `dist`フォルダの内容を任意のフォルダにコピー
3. スタートアップに登録（必要に応じて）

### スタートアップ管理

ビルド後に生成されるbatファイルを使用してスタートアップを管理できます：

```bash
# スタートアップに登録
add-to-startup.bat

# スタートアップから削除
remove-from-startup.bat

# スタートアップ状態を確認
check-startup.bat
```

**注意**: すべてのbatファイルは管理者権限で実行する必要があります。

### アンインストール

現在のアプリケーションをアンインストールするには：

1. アプリケーションを停止
2. アプリケーションフォルダを削除
3. スタートアップから削除（`remove-from-startup.bat`を使用）

```bash
# スタートアップから削除
remove-from-startup.bat
```

## 配布方法

### 配布ファイル

`dist`フォルダの内容をそのまま配布できます：

```
dist/
├── traysvc-amd64.exe      # AMD64用実行ファイル
├── traysvc-arm64.exe      # ARM64用実行ファイル
├── config.json            # 設定ファイル
├── add-to-startup.bat     # スタートアップ登録
├── remove-from-startup.bat # スタートアップ削除
└── check-startup.bat      # スタートアップ状態確認
```

### インストール手順

1. 配布ファイルを任意のフォルダに展開
2. 管理者権限で`add-to-startup.bat`を実行してスタートアップに登録
3. アプリケーションが自動的に起動し、タスクトレイに表示されます

## 使用方法

### 1. 設定ファイルの編集

`config.json`ファイルを編集して監視対象のサービスを設定します：

```json
{
  "poll_interval_sec": 30,
  "services": [
    {"name": "postgresql-x64-16", "display_name": "PostgreSQL"},
    {"name": "Everything", "display_name": "Everything"},
    {"name": "MySQL80", "display_name": "MySQL"},
    {"name": "Apache2.4", "display_name": "Apache"}
  ]
}
```

- `poll_interval_sec`: サービス状態の監視間隔（秒）
- `services`: 監視対象のサービスリスト
  - `name`: Windowsサービスの内部名
  - `display_name`: タスクトレイメニューに表示される名前

### 2. アプリケーションの実行

アプリケーションを実行すると、自動的にUACで管理者権限を求められます：

```bash
# 通常の実行（UACで権限を求める）
.\traysvc.exe
```

または、管理者権限のPowerShellで実行：

```bash
# 管理者権限のPowerShellで実行
.\traysvc.exe
```

### 3. タスクトレイメニューの操作

タスクトレイアイコンを右クリックすると以下のメニューが表示されます：

- **サービス名: 状態**: 各サービスの現在の状態
  - クリックするとサービスの開始/停止を切り替え
- **すべて開始**: 停止中のサービスをすべて開始
- **すべて停止**: 実行中のサービスをすべて停止
- **更新**: サービス状態を手動で更新
- **終了**: アプリケーションを終了

## サービス名の確認方法

Windowsサービスの内部名を確認するには：

1. `services.msc`を実行
2. 対象サービスを右クリック → プロパティ
3. 「サービス名」フィールドの値を`config.json`の`name`に設定

または、PowerShellで以下のコマンドを実行：

```powershell
Get-Service | Where-Object {$_.DisplayName -like "*PostgreSQL*"}
```

## トラブルシューティング

### 権限エラー
サービス操作には管理者権限が必要です。アプリケーションを実行すると自動的にUACで管理者権限を求められます。権限が拒否された場合は、アプリケーションを再起動してください。

### サービスが見つからない
- サービス名が正しいか確認
- サービスが実際にインストールされているか確認

### 通知が表示されない
- Windows通知設定を確認
- アプリケーションが通知を送信する権限があるか確認

## 開発

### 依存関係

- `github.com/getlantern/systray`: タスクトレイ機能
- `github.com/go-toast/toast`: Windows通知
- `golang.org/x/sys/windows/svc`: Windowsサービス操作

### ビルド

#### 開発用ビルド
```bash
# 基本的なビルド
go build -o traysvc.exe

# リリース用ビルド（サイズ最適化）
go build -ldflags="-s -w" -o traysvc.exe
```

#### マルチアーキテクチャビルド
```bash
# AMD64（x64）アーキテクチャ
.\build-amd64.ps1

# ARM64アーキテクチャ
.\build-arm64.ps1

# 両方のアーキテクチャ
.\build-all.ps1
```

#### ビルド出力ファイル
- `traysvc.exe` - 現在のアーキテクチャ用
- `traysvc-amd64.exe` - AMD64（x64）アーキテクチャ用
- `traysvc-arm64.exe` - ARM64アーキテクチャ用
- `config.json` - 設定ファイル
- `add-to-startup.bat` - スタートアップ登録用スクリプト
- `remove-from-startup.bat` - スタートアップ削除用スクリプト
- `check-startup.bat` - スタートアップ状態確認用スクリプト