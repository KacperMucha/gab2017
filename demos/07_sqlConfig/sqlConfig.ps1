Configuration SQL {
    # Fully qualified names doesn't work
    #https://github.com/Azure/azure-powershell/issues/700
    #Import-DscResource -Module PSDesiredStateConfiguration, @{ModuleName='xComputerManagement'; ModuleVersion='1.9.0.0'}, @{ModuleName='xActiveDirectory'; ModuleVersion='2.16.0.0'}
    Import-DscResource -Module PSDesiredStateConfiguration, xComputerManagement, xActiveDirectory

    node $AllNodes.Where({$_.Role -in 'SQL'}).NodeName {
        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
        }

        xWaitForADDomain Domain {
            DomainName = $node.DomainName
            RetryCount = 20
            RetryIntervalSec = 180
        }

        xComputer 'DomainMembership' {
            Name = $node.NodeName;
            DomainName = $node.DomainName;
            Credential = $(New-Object System.Management.Automation.PSCredential ("$($node.DomainName)\azadmin", $(ConvertTo-SecureString "zxcVBN123$%^" -AsPlainText -Force)))
            DependsOn = '[xWaitForADDomain]Domain'
        }

        # On SQL Group resource didn't work
        <#Group LocalAdmins
        {
            Ensure = 'Present'
            GroupName = 'Administrators'
            MembersToInclude = "$($node.DomainName)\CMSiteServers"
            Credential = $(New-Object System.Management.Automation.PSCredential ("$($node.DomainName)\azadmin", $(ConvertTo-SecureString "zxcVBN123$%^" -AsPlainText -Force)))
            DependsOn = '[xWaitForADDomain]Domain'
        }#>

        Script LocalAdmins {
            SetScript = {
                Invoke-Command -ScriptBlock {
                    Write-Verbose -Message 'Adding CMSiteServers group to local Administrators group'
                    net localgroup Administrators /add "CORP\CMSiteServers"
                }
            }
            TestScript = {
                $localAdmins = net localgroup Administrators

                Write-Verbose -Message "Checking if CMSiteServers group is member of local Administrators group"
                if($localAdmins -match 'CMSiteServers') {
                    $true
                } else {
                    $false
                }
            }
            GetScript = {
                $localAdmins = net localgroup Administrators

                @{
                    Result = [string]$localAdmins
                }
            }
            DependsOn = '[xWaitForADDomain]Domain'
        }

        Script DisableFirewall {
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }

            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }

            TestScript = {
                $Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                $Status -eq $True
            }
        }

        Script SetSQLSvcAccount {
            SetScript = {
                Invoke-Command -ScriptBlock {
                    Write-Verbose -Message 'Setting SQL service account credentials to LocalSystem'
                    $sqlService = Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name = 'MSSQLSERVER'"
                    $sqlService.Change($null,$null,$null,$null,$null,$null, ".\LocalSystem", "")
                }
            }
            TestScript = {
                [string]$state = Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name = 'MSSQLSERVER'"
                Write-Verbose -Message "SQL service account credentials: $($state.StartName)"
                if($state.StartName -ne '.\LocalSystem') {
                    $false
                } else {
                    $true
                }
            }
            GetScript = {
                $sqlServiceAccount = (Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name = 'MSSQLSERVER'").StartName
                @{
                    Result = [string]$sqlServiceAccount
                }
            }
        }
    } #end SQL node
}