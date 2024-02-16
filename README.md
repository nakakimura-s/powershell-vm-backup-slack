# 下準備
## Export-VMコマンドのアクセス許可
以下のPowerShellのコマンドを管理者として実行して、実行ポリシーを変更してください。

```
Set-ExecutionPolicy RemoteSigned
```

# タスクスケジューラの設定
タスクの設定から新規設定を行ってください。
## トリガーの設定
ここでは例として毎週月曜日と金曜日にバックアップを設定しています。

![image](https://github.com/nakakimura-s/powershell-vm-backup-slack/assets/160193589/6118ead3-8848-4eb1-8f82-2b01ccf0b568)

## 操作の編集
![image](https://github.com/nakakimura-s/powershell-vm-backup-slack/assets/160193589/e0b30fcb-1521-4408-942c-01158a3a42e0)

プログラム：C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
引数；C:\ps1\powershell-vm-backup-slack.ps1 ※ファイルの配置先
