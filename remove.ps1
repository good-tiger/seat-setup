# 1. Claude Desktop 삭제
winget uninstall Anthropic.Claude

# 2. Claude Code CLI 삭제
winget uninstall Anthropic.ClaudeCode 2>$null
$claudeExe = "$env:USERPROFILE\.local\bin\claude.exe"
if (Test-Path $claudeExe) {
    Remove-Item $claudeExe -Force
    Write-Host "[Done] Claude Code CLI removed" -ForegroundColor Green
} else {
    Write-Host "[Skip] Claude Code CLI not found" -ForegroundColor Yellow
}

# 3. Obsidian 삭제
winget uninstall Obsidian.Obsidian

# 4. GitHub CLI 삭제
winget uninstall GitHub.cli

# 5. PowerShell 프로필에서 git-push-all 제거
if (Test-Path $PROFILE) {
    $content = Get-Content $PROFILE -Raw
    $pattern = '(?s)function git-push-all \{.*?\n\}'
    $newContent = $content -replace $pattern, ''
    $newContent | Out-File -FilePath $PROFILE -Encoding UTF8
    Write-Host "[Done] git-push-all removed from profile" -ForegroundColor Green
}

Write-Host "`nAll uninstalled! Restart PowerShell." -ForegroundColor Green
Read-Host "Press Enter to exit"