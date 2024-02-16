# Slack Webhook URL
$slackUrl = "https://hooks.slack.com/services/xxxxxxxxxxxxxx"

# 保存先のフルパス
$exportPath = "C:\Path\To\Backup\Folder"

# 保持するバックアップの世代数
$generationsToKeep = 3

# 保存先のフォルダが存在しない場合は作成
if (-not (Test-Path $exportPath)) {
    New-Item -Path $exportPath -ItemType Directory | Out-Null
}

# バックアップを作成する仮想マシンのリスト
$vmNameList = @("VM1", "VM2", "VM3")

foreach ($vmName in $vmNameList) {
    $exportFileName = "$vmName-$(Get-Date -Format 'yyyyMMdd-HHmmss').exp"
    $exportFilePath = Join-Path -Path $exportPath -ChildPath $exportFileName
    $exportFailed = $false

    # エクスポートを試行
    try {
        Export-VM -Name $vmName -Path $exportFilePath -Confirm:$false
    } catch {
        Write-Warning "仮想マシン $vmName のエクスポートが失敗しました。エラー: $_"
        $slackMessage = "仮想マシン $vmName のエクスポートが失敗しました。"
        $slackColor = "danger" # アタッチメント赤色
        $exportFailed = $true
    }

    if (-not $exportFailed) {
        # フォルダ配下の.vhdxファイルを取得して合計サイズを計算
        $vhdxFiles = Get-ChildItem -Path $exportFilePath -Filter *.vhdx -Recurse
        $exportFileSize = [math]::Round(($vhdxFiles | Measure-Object -Property Length -Sum).Sum / 1GB, 2)

        if ($exportFileSize -eq 0) {
            # バックアップが失敗した場合のメッセージを構築
            $slackMessage = "仮想マシン $vmName のエクスポートが失敗しました。手動で実行してください。"
            $slackColor = "danger" # アタッチメント赤色
            $exportFileName = "ファイルは作成されてません"
        } else {
            # バックアップが成功した場合のメッセージを構築
            $slackMessage = "仮想マシンのバックアップが完了しました。"
            $slackColor = "good" # アタッチメント緑色
        }

        # Slackにメッセージを送信
        $body = @{
            attachments = @(
                @{
                    text = $slackMessage
                    color = $slackColor
                    fallback = $slackMessage
                    fields = @(
                        @{
                            title = "バックアップファイル名"
                            value = $exportFileName
                            short = $true
                        },
                        @{
                            title = "サイズ(GB)"
                            value = $exportFileSize
                            short = $true
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 4

        Invoke-RestMethod -Uri $slackUrl -Method POST -Body $body -ContentType 'application/json; charset=utf-8'

        # 古いバックアップファイルを削除
        $backupFiles = Get-ChildItem -Path $exportPath | Sort-Object LastWriteTime

        if ($backupFiles.Count -gt $generationsToKeep) {
            $backupFilesToDelete = $backupFiles | Select-Object -First ($backupFiles.Count - $generationsToKeep)

            foreach ($backupFileToDelete in $backupFilesToDelete) {
                # 削除するファイルの情報をSlackに通知するメッセージを作成
                $deletedFileName = $backupFileToDelete.Name
                $slackMessage = "古いバックアップファイルが削除されました。"
                $slackColor = "danger" # アタッチメント赤色

                # Slackにメッセージを送信
                $body = @{
                    attachments = @(
                        @{
                            text = $slackMessage
                            color = $slackColor
                            fallback = $slackMessage
                            fields = @(
                                @{
                                    title = "削除されたファイル名"
                                    value = $deletedFileName
                                    short = $true
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 4
                Invoke-RestMethod -Uri $slackUrl -Method POST -Body $body -ContentType 'application/json; charset=utf-8'

                # ファイルを削除
                Remove-Item -Path $backupFileToDelete.FullName -Force
            }
        } else {
            # Slackに通知するメッセージを作成
            $slackMessage = "残すべきバックアップファイルが指定した世代数よりも少ないため、削除は行いません。"
            $slackColor = "warning" # アタッチメント黄色

            # Slackにメッセージを送信
            $body = @{
                attachments = @(
                    @{
                        text = $slackMessage
                        color = $slackColor
                        fallback = $slackMessage
                    }
                )
            } | ConvertTo-Json -Depth 4

            Invoke-RestMethod -Uri $slackUrl -Method POST -Body $body -ContentType 'application/json; charset=utf-8'
        }
    }
}
