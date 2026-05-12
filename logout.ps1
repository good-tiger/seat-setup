function Confirm-Step {
    param([string]$message)
    Write-Host "`n$message" -ForegroundColor Yellow
    $response = Read-Host "Continue? (y/n)"
    return $response -eq "y"
}

# 1. Obsidian vault commit & push, then delete
if (Confirm-Step "[1/6] Obsidian vault commit, push, delete") {
    $defaultVaultPath = "C:\SSAFY\wiki"
    $inputPath = Read-Host "Vault path (Enter for default: $defaultVaultPath)"
    $vaultPath = if ($inputPath.Trim()) { $inputPath.Trim() } else { $defaultVaultPath }

    if (Test-Path $vaultPath) {
        Set-Location $vaultPath
        git add .
        $status = git status --porcelain
        if ($status) {
            git commit -m "before leaving seat"
            git push
            Write-Host "[Done] Vault committed and pushed" -ForegroundColor Green
        } else {
            Write-Host "[Skip] No changes to commit" -ForegroundColor Yellow
        }
        Set-Location C:\

        Get-Process | Where-Object { $_.Path -like "$vaultPath*" } | ForEach-Object {
            Stop-Process -Id $_.Id -Force
            Write-Host "[Done] Stopped process: $($_.Name)" -ForegroundColor Green
        }
        Start-Sleep -Seconds 1

        Remove-Item -Path $vaultPath -Recurse -Force
        Write-Host "[Done] Vault deleted: $vaultPath" -ForegroundColor Green
    } else {
        Write-Host "[Skip] Vault not found: $vaultPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] Obsidian vault" -ForegroundColor Yellow
}

# 2. Obsidian app config & cache delete (vault 자동 연결 방지)
if (Confirm-Step "[2/8] Obsidian app config & cache delete (forget vaults)") {
    $obsidianProcesses = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
    if ($obsidianProcesses) {
        $obsidianProcesses | Stop-Process -Force
        Start-Sleep -Seconds 1
        Write-Host "[Done] Obsidian process stopped" -ForegroundColor Green
    }

    $obsidianAppData = "$env:APPDATA\obsidian"
    if (Test-Path $obsidianAppData) {
        Remove-Item -Path $obsidianAppData -Recurse -Force
        Write-Host "[Done] Removed: $obsidianAppData" -ForegroundColor Green
    } else {
        Write-Host "[Skip] Obsidian appdata not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] Obsidian app config & cache" -ForegroundColor Yellow
}

# 3. gh logout (all accounts)
if (Confirm-Step "[3/8] GitHub CLI logout (all accounts)") {
    $accounts = gh auth status 2>&1 | Select-String "account" | ForEach-Object {
        ($_ -split "account ")[1] -split " " | Select-Object -First 1
    } | Where-Object { $_ }

    if ($accounts) {
        $accounts | ForEach-Object {
            gh auth logout --hostname github.com --user $_
            Write-Host "[Done] Logged out: $_" -ForegroundColor Green
        }
    } else {
        Write-Host "[Skip] No gh accounts found" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] GitHub CLI logout" -ForegroundColor Yellow
}

# 4. Remove Windows credentials
if (Confirm-Step "[4/8] Remove git/gh Windows credentials") {
    $targets = cmdkey /list | Select-String "git|gh" | ForEach-Object {
        $parts = $_ -split "Target: "
        if ($parts.Count -gt 1) { $parts[1].Trim() }
    } | Where-Object { $_ }

    if ($targets) {
        $targets | ForEach-Object {
            cmdkey /delete:$_
            Write-Host "[Done] Removed: $_" -ForegroundColor Green
        }
    } else {
        Write-Host "[Skip] No git/gh credentials found" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] Windows credentials" -ForegroundColor Yellow
}

# 5. Claude Code logout
if (Confirm-Step "[5/8] Claude Code logout") {
    Write-Host "[Action Required] Please log out manually from Claude Code" -ForegroundColor Magenta
    Write-Host "  1. Run 'claude' in terminal" -ForegroundColor White
    Write-Host "  2. Type /logout and press Enter" -ForegroundColor White
    Write-Host "  3. Close Claude Code" -ForegroundColor White
    Read-Host "Press Enter when done"
} else {
    Write-Host "[Skip] Claude Code logout" -ForegroundColor Yellow
}

# 6. Claude Desktop logout (manual)
if (Confirm-Step "[6/8] Claude Desktop logout (manual required)") {
    Write-Host "[Action Required] Please log out manually from Claude Desktop app" -ForegroundColor Magenta
    Write-Host "  1. Open Claude Desktop" -ForegroundColor White
    Write-Host "  2. Click your profile -> Log out" -ForegroundColor White
    Read-Host "Press Enter when done"
} else {
    Write-Host "[Skip] Claude Desktop logout" -ForegroundColor Yellow
}

# 7. Chrome profiles delete
if (Confirm-Step "[7/8] Delete all Chrome profiles") {
    # 크롬 프로세스 종료
    $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chromeProcesses) {
        Write-Host "[Processing] Closing Chrome..." -ForegroundColor Cyan
        $chromeProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Host "[Done] Chrome closed" -ForegroundColor Green
    }

    $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (Test-Path $chromeUserData) {
        # 프로필 폴더 삭제
        $profiles = Get-ChildItem -Path $chromeUserData -Directory |
            Where-Object { $_.Name -match "^Default$|^Profile \d+$" }

        if ($profiles) {
            $profiles | ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force
                Write-Host "[Done] Removed profile folder: $($_.Name)" -ForegroundColor Green
            }
        }

        # Local State 파일 자체 삭제 (프로필 목록 완전 초기화)
        $localStatePath = Join-Path $chromeUserData "Local State"
        if (Test-Path $localStatePath) {
            Remove-Item $localStatePath -Force
            Write-Host "[Done] Chrome Local State removed" -ForegroundColor Green
        }
    } else {
        Write-Host "[Skip] Chrome User Data path not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] Chrome profiles" -ForegroundColor Yellow
}

# 8. Screenshots folder cleanup
if (Confirm-Step "[8/8] Empty ~/Pictures/Screenshots folder") {
    $screenshotsPath = Join-Path $env:USERPROFILE "Pictures\Screenshots"
    if (Test-Path $screenshotsPath) {
        $items = Get-ChildItem -Path $screenshotsPath -Force
        if ($items) {
            $items | Remove-Item -Recurse -Force
            Write-Host "[Done] Cleared: $screenshotsPath" -ForegroundColor Green
        } else {
            Write-Host "[Skip] Screenshots folder is already empty" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[Skip] Screenshots folder not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "[Skip] Screenshots folder" -ForegroundColor Yellow
}

Write-Host "`nAll done! You can leave your seat safely." -ForegroundColor Green
Read-Host "Press Enter to exit"
