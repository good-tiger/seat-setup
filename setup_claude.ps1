# claude_home/ 의 skills, agents 를 ~/.claude 로 복사한다.
# 기존 항목과 이름이 겹치면 기본적으로 덮어쓴다 (-Merge 옵션이면 같은 이름은 건너뛴다).

param(
    [switch]$Merge  # 같은 이름의 폴더가 이미 있으면 건너뛰기
)

$source = Join-Path $PSScriptRoot "claude_home"
$target = Join-Path $env:USERPROFILE ".claude"

if (-not (Test-Path $source)) {
    Write-Host "[Error] claude_home not found: $source" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

New-Item -ItemType Directory -Force -Path $target | Out-Null

foreach ($kind in @("skills", "agents")) {
    $srcDir = Join-Path $source $kind
    $dstDir = Join-Path $target $kind

    if (-not (Test-Path $srcDir)) {
        Write-Host "[Skip] $kind/ not in claude_home" -ForegroundColor Yellow
        continue
    }

    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null

    $items = Get-ChildItem -Path $srcDir -Force | Where-Object { $_.Name -ne ".gitkeep" }
    if (-not $items) {
        Write-Host "[Skip] $kind/ is empty" -ForegroundColor Yellow
        continue
    }

    foreach ($item in $items) {
        $dstItem = Join-Path $dstDir $item.Name

        if ((Test-Path $dstItem) -and $Merge) {
            Write-Host "[Skip] $kind/$($item.Name) already exists" -ForegroundColor Yellow
            continue
        }

        if (Test-Path $dstItem) {
            Remove-Item -Path $dstItem -Recurse -Force
        }
        Copy-Item -Path $item.FullName -Destination $dstItem -Recurse -Force
        Write-Host "[Done] $kind/$($item.Name)" -ForegroundColor Green
    }
}

Write-Host "`nClaude home setup complete: $target" -ForegroundColor Green
Read-Host "Press Enter to exit"
