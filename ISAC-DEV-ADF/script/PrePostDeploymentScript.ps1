# scripts/PrePostDeploymentScript.ps1
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ResourceGroupName,
  [Parameter(Mandatory = $true)][string]$DataFactoryName,
  [Parameter(Mandatory = $true)][ValidateSet("Stop","Start")][string]$Action,
  [int]$TimeoutSeconds = 90,
  [int]$PollSeconds = 3
)

Write-Host "Data Factory: $DataFactoryName | Resource Group: $ResourceGroupName | Action: $Action"

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.DataFactory -ErrorAction Stop

$triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -ErrorAction Stop

if (-not $triggers) {
  Write-Host "No triggers found."
  return
}

function Get-TriggerStatus {
  param([string]$name)
  try {
    (Get-AzDataFactoryV2TriggerStatus -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $name -ErrorAction Stop).Status
  } catch {
    Write-Warning "Could not get status for trigger '$name': $($_.Exception.Message)"
    $null
  }
}

foreach ($t in $triggers) {
  $name = $t.Name
  $status = Get-TriggerStatus -name $name
  Write-Host "Trigger '$name' current status: ${status}"

  try {
    if ($Action -eq "Stop") {
      if ($status -ne "Stopped") {
        Write-Host "Stopping trigger: $name"
        Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $name -Force -ErrorAction Stop

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        do {
          Start-Sleep -Seconds $PollSeconds
          $status = Get-TriggerStatus -name $name
          Write-Host "  ... waiting, status = $status"
        } while ($status -ne "Stopped" -and $sw.Elapsed.TotalSeconds -lt $TimeoutSeconds)

        if ($status -ne "Stopped") {
          throw "Trigger '$name' did not stop within $TimeoutSeconds seconds. Last status: $status"
        } else {
          Write-Host "Stopped: $name"
        }
      } else {
        Write-Host "Already stopped: $name"
      }
    } else {
      if ($status -ne "Started") {
        Write-Host "Starting trigger: $name"
        Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $name -Force -ErrorAction Stop

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        do {
          Start-Sleep -Seconds $PollSeconds
          $status = Get-TriggerStatus -name $name
          Write-Host "  ... waiting, status = $status"
        } while ($status -ne "Started" -and $sw.Elapsed.TotalSeconds -lt $TimeoutSeconds)

        if ($status -ne "Started") {
          throw "Trigger '$name' did not start within $TimeoutSeconds seconds. Last status: $status"
        } else {
          Write-Host "Started: $name"
        }
      } else {
        Write-Host "Already started: $name"
      }
    }
  } catch {
    Write-Warning "Failed to $Action trigger '$name': $($_.Exception.Message)"
    throw
  }
}



















# # scripts/PrePostDeploymentScript.ps1
# param(
#   [Parameter(Mandatory=$true)][string]$ResourceGroupName,
#   [Parameter(Mandatory=$true)][string]$DataFactoryName,
#   [Parameter(Mandatory=$true)][ValidateSet("Stop","Start")][string]$Action
# )

# Write-Host "Data Factory: $DataFactoryName | Resource Group: $ResourceGroupName | Action: $Action"

# $triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -ErrorAction SilentlyContinue

# if (-not $triggers) {
#   Write-Host "No triggers found."
#   exit 0
# }

# foreach ($t in $triggers) {
#   try {
#     if ($Action -eq "Stop") {
#       if ($t.RuntimeState -eq "Started") {
#         Write-Host "Stopping trigger: $($t.Name)"
#         Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force -ErrorAction Stop
#       } else {
#         Write-Host "Trigger $($t.Name) is already $($t.RuntimeState). Skipping Stop."
#       }
#     } else {
#       Write-Host "Starting trigger: $($t.Name)"
#       Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $t.Name -Force -ErrorAction Stop
#     }
#   } catch {
#     Write-Warning "Failed to $Action trigger $($t.Name): $($_.Exception.Message)"
#     throw
#   }
# }
