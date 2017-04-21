# Basics
Get-Command
Get-Help
Get-Member

# Different ways to achieve the same results
$Running = Get-Service | Where-Object {$_.Status -eq 'running'}
$Running | foreach {$_.Name}
$Running | select -ExpandProperty Name
$Running.Name
(Get-Service | Where-Object {$_.Status -eq 'running'}).Name

# Types, accelerators, convertions
[datetime]"06/22/2016"
[int]"5" | Get-Member
[int]"string" | Get-Member
[System.ServiceProcess.ServiceController]"bits"
[wmi]"root\cimv2:win32_service.name='bits'"
[System.Diagnostics.Process]"ONENOTE"
4 + "str"
"str" + 4

# Checking type constructors
$typeName = 'System.DirectoryServices.ExtendedRightAccessRule'
([type]$typeName).GetConstructors() | ForEach {
    ($_.GetParameters() | ForEach {$_.ToString()}) -Join ", "
}

# Manipulating objects
[pscustomobject]@{
    p1 = 'value1'
    p2 = 'value2'
    p3 = @(1,3,5,6)
} | Export-Csv -notype C:\Scripts\tmp.csv

@(1,3,5,6).ToString()
(@(1,3,5,6) -join ',')

[pscustomobject]@{
    p1 = 'value1'
    p2 = 'value2'
    p3 = (@(1,3,5,6) -join ',')
} | Export-Csv -notype C:\Scripts\tmp.csv

Get-Process powershell | select Name, @{Name='WorkingSet (MB)'; Expression={$_.WorkingSet / 1MB}}

Get-Process | Format-Table Name,@{Name='StartDate';Expression={"{0:d}" -f $_.StartTime}}
Get-Process | Format-Table Name,@{Name='StartDate';Expression={$_.StartTime};FormatString="d"}

# Filtering
Get-WmiObject -Class Win32_Service | where {$_.StartMode -eq "Auto"}
Get-WmiObject -Class Win32_Service -filter "StartMode = 'Auto'"

measure-command {Get-WmiObject -Class Win32_Service | where {$_.StartMode -eq "Auto"}}
measure-command {Get-WmiObject -Class Win32_Service -filter "StartMode = 'Auto'"}

# Functions
Function Test-SuppShouldProcess {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        $File,
        $Destination
    )
    
    process {
        if ($Pscmdlet.ShouldProcess($File,"Move Item")) {
            Move-Item -Path $File -Destination $Destination
        }
    }
}