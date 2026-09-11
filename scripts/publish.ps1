#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Message = ('Update site ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') が失敗しました (exit $LASTEXITCODE)。" }
}

$root = Split-Path -Parent $PSScriptRoot
$tempBuild = $null
$previousResourceDir = $env:HUGO_RESOURCEDIR
Push-Location -LiteralPath $root
try {
    if ([string]::IsNullOrWhiteSpace($Message)) { throw 'commit messageが空です。' }
    $version = & hugo version
    if ($LASTEXITCODE -ne 0) { throw 'Hugoのバージョン確認に失敗しました。' }
    if (($version -join ' ') -notmatch '^hugo v0\.165\.0(?:[-+\s])' -or
        ($version -join ' ') -notmatch '\+extended(?:\s|_)') {
        throw "Hugo 0.165.0 Extendedが必要です。検出: $version"
    }

    $tempBuild = Join-Path ([System.IO.Path]::GetTempPath()) ('hugo-publish-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempBuild | Out-Null
    $env:HUGO_RESOURCEDIR = Join-Path $tempBuild 'resources'
    & hugo --environment production --minify --noBuildLock `
        --destination (Join-Path $tempBuild 'public') --cacheDir (Join-Path $tempBuild 'cache')
    if ($LASTEXITCODE -ne 0) { throw 'Hugoビルドに失敗しました。' }

    Invoke-Git diff --check
    Invoke-Git diff --cached --check
    $changes = Invoke-Git status --porcelain=v1 --untracked-files=all
    if (-not $changes) {
        Write-Output '変更はありません。commit / pushは行いません。'
        return
    }
    $changes | Write-Output

    # 別ブランチや入れ子のリポジトリから誤って公開しない。
    $gitRoot = Invoke-Git rev-parse --show-toplevel
    if ([System.IO.Path]::GetFullPath($gitRoot) -ne [System.IO.Path]::GetFullPath($root)) {
        throw 'scriptsの親ディレクトリがGitリポジトリのルートではありません。'
    }
    $branch = Invoke-Git branch --show-current
    if ($branch -ne 'main') { throw '公開はmainブランチで実行してください。' }
    Invoke-Git remote get-url origin
    Invoke-Git add .
    # 未追跡だったファイルもcommit前に検査する。
    Invoke-Git diff --cached --check
    Invoke-Git commit -m $Message
    Invoke-Git push origin main
}
catch {
    Write-Error "公開に失敗しました: $_"
    exit 1
}
finally {
    $env:HUGO_RESOURCEDIR = $previousResourceDir
    Pop-Location
    if ($tempBuild -and (Test-Path -LiteralPath $tempBuild)) {
        # この実行で作成した一時ディレクトリだけを削除する。
        $resolved = [System.IO.Path]::GetFullPath($tempBuild)
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if ([System.IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/') -eq $tempRoot.TrimEnd('\', '/') -and
            [System.IO.Path]::GetFileName($resolved) -like 'hugo-publish-*') {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}
