param(
 [string]$PsqlPath = 'D:/PostgreSQL/18/bin/psql.exe',
 [string]$Server = '127.0.0.1',
 [int]$Port = 5432,
 [string]$Database = 'olist_customer_analytics',
 [string]$User = 'olist_analyst',
 [string]$PassFile = $env:PGPASSFILE
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$previousPassFile = $env:PGPASSFILE
$previousEncoding = $env:PGCLIENTENCODING
Push-Location -LiteralPath $projectRoot
try {
 if (-not (Test-Path -LiteralPath $PsqlPath)) { throw 'Set -PsqlPath to your PostgreSQL psql executable.' }
 if ($PassFile) { $env:PGPASSFILE = $PassFile }
 $env:PGCLIENTENCODING = 'UTF8'
 $connection = @('-X','-w','-h',$Server,'-p',$Port,'-U',$User,'-d',$Database,'-v','ON_ERROR_STOP=1')
 foreach ($file in @(
  '02_data_preparation.sql','03_customer_purchase_metrics.sql','04_rfm_analysis.sql',
  '05_cohort_analysis.sql','06_repeat_purchase_analysis.sql','07_purchase_intervals.sql',
  '08_powerbi_views.sql','09_validation.sql','10_export_results.psql'
 )) {
  Write-Output ("Running "+$file)
  & $PsqlPath @connection -f (Join-Path 'sql' $file)
  if ($LASTEXITCODE -ne 0) { throw ("Failed: "+$file) }
 }
 Copy-Item -LiteralPath 'outputs/tables/analysis_results.json' -Destination 'docs/ANALYSIS_RESULTS.json'
 Write-Output 'SQL analysis, validation and local exports completed. Refresh Power BI separately.'
} finally {
 $env:PGPASSFILE = $previousPassFile
 $env:PGCLIENTENCODING = $previousEncoding
 Pop-Location
}
