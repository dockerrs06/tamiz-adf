# scripts/PrePostDeploymentScript.ps1
param(
  [Parameter(Mandatory=$true)][string]$ResourceGroupName,
  [Parameter(Mandatory=$true)][string]$DataFactoryName,
  [Parameter(Mandatory=$true)][ValidateSet("Stop","Start")][string]$Action
)

Write-Host "Data Factory: $DataFactoryName | Resource Group: $ResourceGroupName | Action: $Action"

$triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -ErrorAction SilentlyContinue

if (-not $triggers) {
  Write-Host "No triggers found."
  exit 0
}

foreach ($t in $triggers) {
  try {
    if ($Action -eq "Stop") {
      if ($t.RuntimeState -eq "Started") {
        Write-Host "Stopping trigger: $($t.Name)"
        Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force -ErrorAction Stop
      } else {
        Write-Host "Trigger $($t.Name) is already $($t.RuntimeState). Skipping Stop."
      }
    } else {
      Write-Host "Starting trigger: $($t.Name)"
      Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force -ErrorAction Stop
    }
  } catch {
    Write-Warning "Failed to $Action trigger $($t.Name): $($_.Exception.Message)"
    throw
  }
}
