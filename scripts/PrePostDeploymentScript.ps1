param(
  [Parameter(Mandatory=$true)][string]$ResourceGroupName,
  [Parameter(Mandatory=$true)][string]$DataFactoryName,
  [Parameter(Mandatory=$true)][ValidateSet("Stop","Start")][string]$Action
)

$triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -ErrorAction SilentlyContinue

if (-not $triggers) {
  Write-Host "No triggers found."
  exit 0
}

foreach ($t in $triggers) {
  if ($Action -eq "Stop") {
    Write-Host "Stopping trigger: $($t.Name)"
    Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force
  }
  else {
    Write-Host "Starting trigger: $($t.Name)"
    Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force
  }
}
