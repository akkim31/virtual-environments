################################################################################
##  File:  Install-AliyunCli.ps1
##  Desc:  Install Alibaba Cloud CLI
################################################################################

Write-Host "Download Latest aliyun-cli archive"
$url = 'https://api.github.com/repos/aliyun/aliyun-cli/releases/latest'
# Explicitly set type to string since match returns array by default
[System.String] $aliyunLatest = (Invoke-RestMethod -Uri $url).assets.browser_download_url -match "aliyun-cli-windows"
$aliyunArchivePath = Start-DownloadWithRetry -Url $aliyunLatest -Name "aliyin-cli.zip"

Write-Host "Expand aliyun-cli archive"
# Expand aliyun.exe to System32 directory
$DestinationPath = [System.Environment]::SystemDirectory
Extract-7Zip -Path $aliyunArchivePath -DestinationPath $DestinationPath

Invoke-PesterTests -TestFile "Tools" -TestName "AliyunCli"