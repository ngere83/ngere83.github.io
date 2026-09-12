#requires -Version 7.0
# Shared path validation. Reparse points are rejected, including ancestor junctions.
$TrashSiteRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$TrashContentRoot = Join-Path $TrashSiteRoot 'content'
$TrashRoot = Join-Path $TrashSiteRoot '.trash'

function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor -and $cursor -ne $TrashSiteRoot) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "リンク・ジャンクションは扱えません: $cursor"
            }
        }
        $cursor = Split-Path -Parent $cursor
    }
}

function Get-PostPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($TrashContentRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'content/ 内の投稿だけを指定してください。'
    }
    Assert-PlainPath $full
    $relative = [IO.Path]::GetRelativePath($TrashContentRoot, $full)
    if (($relative -split '[\\/]').Count -lt 2 -or [IO.Path]::GetFileName($full) -ieq '_index.md') {
        throw 'Sectionや_index.mdは移動できません。'
    }
    return $full
}

function Assert-PostItem([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path 'index.md') -PathType Leaf)) {
            throw 'ディレクトリはindex.mdを持つページバンドルだけ指定できます。'
        }
        foreach ($child in Get-ChildItem -LiteralPath $Path -Recurse -Force) {
            if ($child.Name -ieq '_index.md' -or ($child.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw 'Sectionやリンクを含むバンドルは移動できません。'
            }
        }
    } elseif ($item.Extension -ine '.md' -or $item.Name -ieq '_index.md') {
        throw '単体Markdownまたはページバンドルを指定してください。'
    } elseif ($item.Name -ieq 'index.md') {
        throw 'index.md単体ではなくページバンドルのディレクトリを指定してください。'
    }
    return $item
}

function Read-TrashItem([string]$Id) {
    if ($Id -notmatch '^\d{8}-\d{6}-[a-f0-9]{32}$') { throw '不正なゴミ箱IDです。' }
    $directory = Join-Path $TrashRoot $Id
    Assert-PlainPath (Join-Path $directory 'metadata.json')
    $metadata = Get-Content -LiteralPath (Join-Path $directory 'metadata.json') -Raw | ConvertFrom-Json
    if ($metadata.Id -cne $Id -or $metadata.Kind -notin @('file', 'directory') -or
        [IO.Path]::IsPathRooted($metadata.OriginalPath) -or $metadata.OriginalPath -match '(^|[\\/])\.\.([\\/]|$)') {
        throw 'ゴミ箱メタデータが不正です。'
    }
    $destination = Get-PostPath (Join-Path $TrashSiteRoot $metadata.OriginalPath)
    $payload = Join-Path $directory 'payload'
    Assert-PlainPath $payload
    $children = @(Get-ChildItem -LiteralPath $payload -Force)
    if ($children.Count -ne 1 -or $children[0].Name -cne [IO.Path]::GetFileName($destination)) { throw 'ゴミ箱の内容が一致しません。' }
    Assert-PlainPath $children[0].FullName
    $item = Assert-PostItem $children[0].FullName
    if ($item.PSIsContainer -ne ($metadata.Kind -eq 'directory')) { throw 'ゴミ箱の種類が一致しません。' }
    return [pscustomobject]@{ Metadata = $metadata; Directory = $directory; Payload = $payload; Source = $item.FullName; Destination = $destination }
}
