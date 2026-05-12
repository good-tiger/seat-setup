# tokens.txt에서 GitHub Personal Access Token을 읽어 gh CLI 자동 로그인
# 형식: 한 줄에 토큰 하나, '#'로 시작하는 줄과 빈 줄은 무시

$tokenFile = Join-Path $PSScriptRoot "tokens.txt"

if (-not (Test-Path $tokenFile)) {
    Write-Host "[Error] tokens.txt not found: $tokenFile" -ForegroundColor Red
    Write-Host "        Create the file and put one token per line." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[Error] gh CLI not found. Run setup.ps1 first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$tokens = Get-Content $tokenFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

if (-not $tokens) {
    Write-Host "[Error] No tokens found in tokens.txt" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$index = 0
foreach ($token in $tokens) {
    $index++
    Write-Host "`n[Processing] Token #$index" -ForegroundColor Cyan

    $token | gh auth login --hostname github.com --git-protocol https --with-token
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[Done] Logged in with token #$index" -ForegroundColor Green
    } else {
        Write-Host "[Fail] Token #$index login failed" -ForegroundColor Red
    }
}

# git 인증을 gh로 위임 (credential helper 설정)
Write-Host "`n[Processing] Setting gh as git credential helper" -ForegroundColor Cyan
gh auth setup-git
if ($LASTEXITCODE -eq 0) {
    Write-Host "[Done] git credential helper configured" -ForegroundColor Green
}

Write-Host "`nLogin complete. Current status:" -ForegroundColor Green
gh auth status

Read-Host "`nPress Enter to exit"
