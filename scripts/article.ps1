#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,

    [ValidateSet('notes', 'tech', 'food', 'art', 'games')]
    [string]$Section = 'notes',

    [AllowEmptyString()]
    [string]$Body = '',

    [ValidateNotNullOrEmpty()]
    [string]$Date,

    [switch]$Open
)

$ErrorActionPreference = 'Stop'
try {
    if ([string]::IsNullOrWhiteSpace($Title)) { throw 'タイトルを指定してください。' }
    $root = Split-Path -Parent $PSScriptRoot
    $directory = Join-Path $root "content/$($Section.ToLowerInvariant())"
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        throw "投稿先がありません: $directory"
    }

    $now = if ($PSBoundParameters.ContainsKey('Date')) {
        & "$PSScriptRoot/resolve-post-date.ps1" -Date $Date
    } else { [DateTimeOffset]::Now }
    $path = Join-Path $directory ($now.ToString('yyyyMMdd-HHmmss') + '.md')
    $escapedTitle = ConvertTo-Json -InputObject $Title -Compress
    $markdown = "+++`ntitle = $escapedTitle`ndate = '$($now.ToString('o'))'`ndraft = false`nentryType = `"article`"`n+++`n"
    # 改行をLFに統一し、末尾の空白・空行だけを除去する。
    $content = $Body.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char[]]" `t`n")
    if ($content.Length -gt 0) { $markdown += "`n$content`n" }

    # postと同様に、同名の既存記事は上書きしない。
    $stream = [System.IO.File]::Open($path, 'CreateNew', 'Write', 'None')
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($markdown)
        $stream.Write($bytes, 0, $bytes.Length)
    }
    finally { $stream.Dispose() }

    Write-Output $path
    if ($Open -or -not $PSBoundParameters.ContainsKey('Body')) {
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $path)
    }
}
catch {
    Write-Error "記事作成に失敗しました: $_"
    exit 1
}
