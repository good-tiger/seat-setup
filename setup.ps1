# 설치할 항목 정의
$items = @(
    @{ Key = "claude-desktop"; Label = "Claude Desktop" }
    @{ Key = "claude-code";    Label = "Claude Code CLI" }
    @{ Key = "obsidian";       Label = "Obsidian" }
    @{ Key = "gh";             Label = "GitHub CLI" }
    @{ Key = "git-push-all";   Label = "git-push-all to PowerShell profile" }
)

# 1단계: 설치할 항목 선택
Write-Host "`nSelect items to install:" -ForegroundColor Cyan
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

Write-Host "`nWill install:" -ForegroundColor Cyan
$selected | ForEach-Object { Write-Host "  - $($_.Label)" -ForegroundColor White }
$confirm = Read-Host "`nProceed? (y/n)"
if ($confirm -ne "y") {
    Write-Host "[Cancelled]" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# 2단계: 선택된 항목 설치
$keys = $selected | ForEach-Object { $_.Key }

if ($keys -contains "claude-desktop") {
    Write-Host "`n[Processing] Claude Desktop" -ForegroundColor Cyan
    winget install Anthropic.Claude
}

if ($keys -contains "claude-code") {
    Write-Host "`n[Processing] Claude Code CLI" -ForegroundColor Cyan
    winget install Anthropic.ClaudeCode
}

if ($keys -contains "obsidian") {
    Write-Host "`n[Processing] Obsidian" -ForegroundColor Cyan
    winget install Obsidian.Obsidian
}

if ($keys -contains "gh") {
    Write-Host "`n[Processing] GitHub CLI" -ForegroundColor Cyan
    winget install GitHub.cli
}

if ($keys -contains "git-push-all") {
    Write-Host "`n[Processing] git-push-all to PowerShell profile" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
    @'
function git-push-all {
    param([string]$path = (Get-Location))

    Get-ChildItem -Path $path -Directory | ForEach-Object {
        $folder = $_.Name
        Write-Host "`n[Processing] $folder" -ForegroundColor Cyan

        Set-Location $_.FullName
        git add .

        $status = git status --porcelain
        if ($status) {
            git commit -m "실습"
            git push
            Write-Host "[Done] $folder" -ForegroundColor Green
        } else {
            Write-Host "[Skip] $folder - no changes" -ForegroundColor Yellow
        }

        Set-Location $path
    }
}
'@ | Out-File -FilePath $PROFILE -Encoding UTF8
    Write-Host "[Done] git-push-all added to profile" -ForegroundColor Green
}

Write-Host "`nAll done! Restart PowerShell." -ForegroundColor Green
Read-Host "Press Enter to exit"
