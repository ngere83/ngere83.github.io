#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,

    [ValidateNotNullOrEmpty()]
    [string]$Date,

    [switch]$Open
)

$ErrorActionPreference = 'Stop'
try {
    if ([string]::IsNullOrWhiteSpace($Title)) { throw 'タイトルを指定してください。' }
    $root = Split-Path -Parent $PSScriptRoot
    $directory = Join-Path $root 'content/shorts'
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        throw "投稿先がありません: $directory"
    }

    $now = if ($PSBoundParameters.ContainsKey('Date')) {
        & "$PSScriptRoot/resolve-post-date.ps1" -Date $Date
    } else { [DateTimeOffset]::Now }
    $path = Join-Path $directory ($now.ToString('yyyyMMdd-HHmmss') + '.md')
    # JSONの文字列エスケープはTOMLの基本文字列でも使用できる。
    $escapedTitle = ConvertTo-Json -InputObject $Title -Compress
    $markdown = "+++`ntitle = $escapedTitle`ndate = '$($now.ToString('o'))'`ndraft = false`nentryType = `"short`"`n+++`n"
    # 同じ秒に実行した場合も、既存記事を上書きしない。
    $stream = [System.IO.File]::Open($path, 'CreateNew', 'Write', 'None')
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($markdown)
        $stream.Write($bytes, 0, $bytes.Length)
    }
    finally { $stream.Dispose() }

    Write-Output $path
    if ($Open) {
        # Windows標準のメモ帳でMarkdownの関連付けに依存せず編集する。
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $path)
    }
}
catch {
    Write-Error "投稿作成に失敗しました: $_"
    exit 1
}
