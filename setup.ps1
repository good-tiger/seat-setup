# 1. Claude Desktop 설치
winget install Anthropic.Claude

# 2. Claude Code CLI 설치 (Node.js 불필요)
winget install Anthropic.ClaudeCode

# 3. Obsidian 설치
winget install Obsidian.Obsidian

# 4. GitHub CLI 설치
winget install GitHub.cli

# 5. git-push-all 프로필 등록
New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null; @'
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

Write-Host "`nAll done! Restart PowerShell." -ForegroundColor Green
Read-Host "Press Enter to exit"