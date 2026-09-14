#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$File,

    [ValidateSet('art', 'notes', 'tech', 'food', 'games')]
    [string]$Section = 'art',

    [string]$Caption = '',
    [ValidateNotNullOrEmpty()]
    [string]$Date,

    [switch]$Open
)

$ErrorActionPreference = 'Stop'
try {
    if ([string]::IsNullOrWhiteSpace($Title)) { throw 'タイトルを指定してください。' }
    $source = Get-Item -LiteralPath $File
    if ($source -isnot [System.IO.FileInfo]) { throw '画像ファイルを指定してください。' }
    $extension = $source.Extension.ToLowerInvariant()
    if ($extension -notin @('.png', '.jpg', '.jpeg', '.webp', '.gif')) {
        throw "非対応の画像形式です: $extension (png / jpg / jpeg / webp / gifに対応)"
    }
    $root = Split-Path -Parent $PSScriptRoot
    $directory = Join-Path $root "content/$($Section.ToLowerInvariant())"
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "投稿先がありません: $directory" }

    $now = if ($PSBoundParameters.ContainsKey('Date')) {
        & "$PSScriptRoot/resolve-post-date.ps1" -Date $Date
    } else { [DateTimeOffset]::Now }
    $bundle = Join-Path $directory ($now.ToString('yyyyMMdd-HHmmss'))
    # 元の名前に依存しない安全なコピー名。元画像の内容・名前は変更しない。
    $imageName = 'image' + $extension
    $escapedTitle = ConvertTo-Json -InputObject $Title -Compress
    $alt = [System.Net.WebUtility]::HtmlEncode($Title.Replace("`r", ' ').Replace("`n", ' '))
    $alt = [regex]::Replace($alt, '([\\`*_{}\[\]()!])', '\$1')
    $markdown = "+++`ntitle = $escapedTitle`ndate = '$($now.ToString('o'))'`ndraft = false`nentryType = `"image`"`n`n[cover]`nimage = `"$imageName`"`nalt = $escapedTitle`nhiddenInSingle = true`n+++`n`n![$alt]($imageName)`n"
    # 個別ページは本文の画像を使い、coverとの二重表示を避ける。
    $content = $Caption.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char[]]" `t`n")
    if ($content.Length -gt 0) { $markdown += "`n$content`n" }

    # 同じ日時のフォルダがあれば停止し、既存投稿を上書きしない。
    New-Item -ItemType Directory -Path $bundle | Out-Null
    Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $bundle $imageName)
    $path = Join-Path $bundle 'index.md'
    [System.IO.File]::WriteAllText($path, $markdown, [System.Text.UTF8Encoding]::new($false))
    Write-Output $path
    if ($Open) { Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $path) }
}
catch {
    Write-Error "画像投稿に失敗しました: $_"
    exit 1
}
