# tokens.txt에서 토큰을 읽어 자동 로그인
# 형식: 한 줄에 "<host> <token>"
#   - host 생략 시 github.com으로 간주
#   - github.com → gh CLI 로그인
#   - 그 외(예: lab.ssafy.com) → git credential approve로 Windows 자격 증명에 저장
# '#'로 시작하는 줄과 빈 줄은 무시

$tokenFile = Join-Path $PSScriptRoot "tokens.txt"

if (-not (Test-Path $tokenFile)) {
    Write-Host "[Error] tokens.txt not found: $tokenFile" -ForegroundColor Red
    Write-Host "        Create the file based on tokens.example.txt" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

$lines = Get-Content $tokenFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

if (-not $lines) {
    Write-Host "[Error] No tokens found in tokens.txt" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

foreach ($line in $lines) {
    $parts = $line -split '\s+', 2
    if ($parts.Count -eq 1) {
        $hostname = "github.com"
        $token = $parts[0]
    } else {
        $hostname = $parts[0]
        $token = $parts[1]
    }

    Write-Host "`n[Processing] $hostname" -ForegroundColor Cyan

    if ($hostname -eq "github.com") {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "[Fail] gh CLI not found. Run setup.ps1 first." -ForegroundColor Red
            continue
        }
        $token | gh auth login --hostname github.com --git-protocol https --with-token
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[Done] gh logged in: $hostname" -ForegroundColor Green
        } else {
            Write-Host "[Fail] gh login failed: $hostname" -ForegroundColor Red
        }
    } else {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "[Fail] git not found." -ForegroundColor Red
            continue
        }
        $credInput = @(
            "protocol=https",
            "host=$hostname",
            "username=oauth2",
            "password=$token",
            ""
        ) -join "`n"
        $credInput | git credential approve
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[Done] git credential saved: $hostname (user: oauth2)" -ForegroundColor Green
        } else {
            Write-Host "[Fail] git credential save failed: $hostname" -ForegroundColor Red
        }
    }
}

# github.com만 gh를 git credential helper로 위임
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "`n[Processing] Setting gh as git credential helper for github.com" -ForegroundColor Cyan
    gh auth setup-git
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[Done] git credential helper configured" -ForegroundColor Green
    }

    Write-Host "`nLogin complete. Current gh status:" -ForegroundColor Green
    gh auth status
}

Read-Host "`nPress Enter to exit"
