function Confirm-Step {
    param([string]$message)
    Write-Host "`n$message" -ForegroundColor Yellow
    $response = Read-Host "Continue? (y/n)"
    return $response -eq "y"
}

# 1. Token-based login (gh CLI + git credentials)
# tokens.txt 형식: 한 줄에 "<host> <token>"
#   - host 생략 시 github.com으로 간주
#   - github.com → gh CLI 로그인
#   - 그 외(예: lab.ssafy.com) → git credential approve로 Windows 자격 증명에 저장
# '#'로 시작하는 줄과 빈 줄은 무시
if (Confirm-Step "[1/3] Token-based login (gh CLI + git credentials)") {
    $tokenFile = Join-Path $PSScriptRoot "tokens.txt"

    if (-not (Test-Path $tokenFile)) {
        Write-Host "[Error] tokens.txt not found: $tokenFile" -ForegroundColor Red
        Write-Host "        Create the file based on tokens.example.txt" -ForegroundColor Yellow
    } else {
        $lines = Get-Content $tokenFile |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") }

        if (-not $lines) {
            Write-Host "[Error] No tokens found in tokens.txt" -ForegroundColor Red
        } else {
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
        }
    }
} else {
    Write-Host "[Skip] Token-based login" -ForegroundColor Yellow
}

# 2. Claude Code login (manual)
if (Confirm-Step "[2/3] Claude Code login (manual required)") {
    Write-Host "[Action Required] Please log in manually to Claude Code" -ForegroundColor Magenta
    Write-Host "  1. Run 'claude' in terminal" -ForegroundColor White
    Write-Host "  2. Type /login and press Enter" -ForegroundColor White
    Write-Host "  3. Complete the browser authentication" -ForegroundColor White
    Read-Host "Press Enter when done"
} else {
    Write-Host "[Skip] Claude Code login" -ForegroundColor Yellow
}

# 3. Claude Desktop login (manual)
if (Confirm-Step "[3/3] Claude Desktop login (manual required)") {
    Write-Host "[Action Required] Please log in manually to Claude Desktop app" -ForegroundColor Magenta
    Write-Host "  1. Open Claude Desktop" -ForegroundColor White
    Write-Host "  2. Click 'Log in' and complete authentication" -ForegroundColor White
    Read-Host "Press Enter when done"
} else {
    Write-Host "[Skip] Claude Desktop login" -ForegroundColor Yellow
}

Write-Host "`nAll done! Have a productive session." -ForegroundColor Green
Read-Host "Press Enter to exit"
