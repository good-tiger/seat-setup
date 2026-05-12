# 삭제할 항목 정의
$items = @(
    @{ Key = "claude-desktop"; Label = "Claude Desktop" }
    @{ Key = "claude-code";    Label = "Claude Code CLI" }
    @{ Key = "obsidian";       Label = "Obsidian" }
    @{ Key = "gh";             Label = "GitHub CLI" }
    @{ Key = "git-push-all";   Label = "git-push-all from PowerShell profile" }
)

# 1단계: 삭제할 항목 선택
Write-Host "`nSelect items to remove:" -ForegroundColor Cyan
for ($i = 0; $i -lt $items.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $items[$i].Label) -ForegroundColor White
}
Write-Host "`nEnter numbers separated by commas (e.g., 1,3,5) or 'all' for everything." -ForegroundColor Yellow
$input = Read-Host "Selection"

$selected = @()
if ($input.Trim().ToLower() -eq "all") {
    $selected = $items
} else {
    $indices = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    foreach ($idx in $indices) {
        $n = [int]$idx
        if ($n -ge 1 -and $n -le $items.Count) {
            $selected += $items[$n - 1]
        }
    }
}

if (-not $selected) {
    Write-Host "`n[Skip] No items selected. Exiting." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host "`nWill remove:" -ForegroundColor Cyan
$selected | ForEach-Object { Write-Host "  - $($_.Label)" -ForegroundColor White }
$confirm = Read-Host "`nProceed? (y/n)"
if ($confirm -ne "y") {
    Write-Host "[Cancelled]" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# 2단계: 선택된 항목 삭제
$keys = $selected | ForEach-Object { $_.Key }

if ($keys -contains "claude-desktop") {
    Write-Host "`n[Processing] Claude Desktop" -ForegroundColor Cyan
    winget uninstall Anthropic.Claude
}

if ($keys -contains "claude-code") {
    Write-Host "`n[Processing] Claude Code CLI" -ForegroundColor Cyan
    winget uninstall Anthropic.ClaudeCode 2>$null
    $claudeExe = "$env:USERPROFILE\.local\bin\claude.exe"
    if (Test-Path $claudeExe) {
        Remove-Item $claudeExe -Force
        Write-Host "[Done] Claude Code CLI removed" -ForegroundColor Green
    } else {
        Write-Host "[Skip] Claude Code CLI not found" -ForegroundColor Yellow
    }
}

if ($keys -contains "obsidian") {
    Write-Host "`n[Processing] Obsidian" -ForegroundColor Cyan
    winget uninstall Obsidian.Obsidian
}

if ($keys -contains "gh") {
    Write-Host "`n[Processing] GitHub CLI" -ForegroundColor Cyan
    winget uninstall GitHub.cli
}

if ($keys -contains "git-push-all") {
    Write-Host "`n[Processing] git-push-all from PowerShell profile" -ForegroundColor Cyan
    if (Test-Path $PROFILE) {
        $content = Get-Content $PROFILE -Raw
        $pattern = '(?s)function git-push-all \{.*?\n\}'
        $newContent = $content -replace $pattern, ''
        $newContent | Out-File -FilePath $PROFILE -Encoding UTF8
        Write-Host "[Done] git-push-all removed from profile" -ForegroundColor Green
    } else {
        Write-Host "[Skip] PowerShell profile not found" -ForegroundColor Yellow
    }
}

Write-Host "`nAll done! Restart PowerShell." -ForegroundColor Green
Read-Host "Press Enter to exit"
