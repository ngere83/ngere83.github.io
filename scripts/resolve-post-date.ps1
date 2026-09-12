#requires -Version 7.0
param([Parameter(Mandatory)][string]$Date)
$ErrorActionPreference = 'Stop'
$formats = [string[]]@('yyyy-MM-dd', 'yyyy-MM-dd HH:mm', 'yyyy-MM-dd HH:mm:ss',
    'yyyy/MM/dd', 'yyyy/MM/dd HH:mm', 'yyyy/MM/dd HH:mm:ss')
$parsed = [datetime]::MinValue
if (-not [datetime]::TryParseExact($Date, $formats, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
    throw "日時を解釈できません: '$Date'。例: 2026-09-05 21:30"
}
if ([TimeZoneInfo]::Local.IsInvalidTime($parsed) -or [TimeZoneInfo]::Local.IsAmbiguousTime($parsed)) {
    throw "ローカルタイムゾーンで日時が一意に定まりません: '$Date'"
}
[DateTimeOffset]::new($parsed, [TimeZoneInfo]::Local.GetUtcOffset($parsed))
