#requires -Version 7.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/trash-common.ps1"
Assert-PlainPath $TrashRoot
if (Test-Path -LiteralPath $TrashRoot) {
    Get-ChildItem -LiteralPath $TrashRoot -Directory | Sort-Object Name -Descending | ForEach-Object {
        (Read-TrashItem $_.Name).Metadata | Select-Object Id, DeletedAt, Title, OriginalPath, Kind
    }
}
