#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Id)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/trash-common.ps1"
$entry = Read-TrashItem $Id
if (Test-Path -LiteralPath $entry.Destination) { throw "復元先が既に存在します: $($entry.Destination)" }
$parent = Split-Path -Parent $entry.Destination
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw "復元先の親ディレクトリがありません: $parent" }
# Move APIs refuse an existing destination, including a collision during restore.
if ($entry.Metadata.Kind -eq 'directory') { [IO.Directory]::Move($entry.Source, $entry.Destination) }
else { [IO.File]::Move($entry.Source, $entry.Destination) }
# Remove only metadata and empty containers after successful restoration.
[IO.Directory]::Delete($entry.Payload, $false)
Remove-Item -LiteralPath (Join-Path $entry.Directory 'metadata.json')
[IO.Directory]::Delete($entry.Directory, $false)
Write-Output $entry.Destination
