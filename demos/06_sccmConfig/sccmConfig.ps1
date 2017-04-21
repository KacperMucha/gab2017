Configuration SCCM {
    # Fully qualified names doesn't work
    #https://github.com/Azure/azure-powershell/issues/700
    #Import-DscResource -Module PSDesiredStateConfiguration, @{ModuleName='xComputerManagement'; ModuleVersion='1.9.0.0'}, @{ModuleName='xActiveDirectory'; ModuleVersion='2.16.0.0'}
    Import-DscResource -Module PSDesiredStateConfiguration, xComputerManagement, xActiveDirectory

    node $AllNodes.Where({$_.Role -in 'SCCM'}).NodeName {
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
            Name = $node.NodeName
            DomainName = $node.DomainName
            # Don't do this in production!
            Credential = $(New-Object System.Management.Automation.PSCredential ("$($node.DomainName)\azadmin", $(ConvertTo-SecureString "zxcVBN123$%^" -AsPlainText -Force)))
            DependsOn = '[xWaitForADDomain]Domain'
        }

        # Use of configuration data
        $Node.Features.Foreach({
            WindowsFeature $_
            {
                Name = $_
                Ensure = 'Present'
            }
        })

        # Does not work on every node
        Group LocalAdmins
        {
            Ensure = 'Present'
            GroupName = 'Administrators'
            MembersToInclude = "$($node.DomainName)\CMAdmins", "$($node.DomainName)\CMSiteServers"
            Credential = $(New-Object System.Management.Automation.PSCredential ("$($node.DomainName)\azadmin", $(ConvertTo-SecureString "zxcVBN123$%^" -AsPlainText -Force)))
            DependsOn = '[xWaitForADDomain]Domain'
        }

        File Resources {
            Ensure = 'Present'
            DestinationPath = 'C:\Resources'
            Type = 'Directory'
        }

        File Preqs {
            Ensure = 'Present'
            DestinationPath = 'C:\Resources\Preqs'
            Type = 'Directory'
            DependsOn = '[File]Resources'
        }

        # Script resource serialization
        Script ADK
        {
            SetScript = { 
                Invoke-Command -ScriptBlock { 
                    Start-BitsTransfer -Source 'http://download.microsoft.com/download/9/A/E/9AE69DD5-BA93-44E0-864E-180F5E700AB4/adk/adksetup.exe' -Destination 'C:\Resources'
                }
            }
            TestScript = {
                [string]$state = Test-Path -Path 'C:\Resources\adksetup.exe'
                if($state -eq 'false') {
                    $false
                } else {
                    $true
                }
            }
            GetScript = {
                $sccmBinaryExists = Test-Path -Path 'C:\Resources\adksetup.exe'
                @{
                    Result = [string]$sccmBinaryExists
                }
            }
            DependsOn = '[File]Resources'
        }

        Package InstallADK
        {
            Ensure = 'Present'
            Name = 'ADK'
            Path = 'C:\Resources\adksetup.exe'
            ProductId = '39ebb79f-797c-418f-b329-97cfdf92b7ab'
            Arguments = '/Features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.WindowsPreinstallationEnvironment OptionId.ImagingAndConfigurationDesigner /norestart /quiet /ceip off'
            DependsOn = '[Script]ADK'
        }

        Script ConfigMgrSetup
        {
            SetScript = { 
                Invoke-Command -ScriptBlock { 
                    Start-BitsTransfer -Source 'http://care.dlservice.microsoft.com/dl/download/F/B/9/FB9B10A3-4517-4E03-87E6-8949551BC313/SC_Configmgr_SCEP_1606.exe' -Destination 'C:\Resources'
                }
            }
            TestScript = {
                [string]$state = Test-Path -Path 'C:\Resources\SC_Configmgr_SCEP_1606.exe'
                if($state -eq 'false') {
                    $false
                } else {
                    $true
                }
            }
            GetScript = {
                $sccmBinaryExists = Test-Path -Path 'C:\Resources\SC_Configmgr_SCEP_1606.exe'
                @{
                    Result = [string]$sccmBinaryExists
                }
            }
            DependsOn = '[File]Resources'
        }

        Script ExtractConfigMgrSetup
        {
            SetScript = {
                Invoke-Command -ScriptBlock {
                    # Wait for process to finish
                    $process = [System.Diagnostics.Process]::Start('C:\Resources\SC_Configmgr_SCEP_1606.exe', '/auto C:\Resources\SCCM') 
                    $process.WaitForExit()
                }
            }
            TestScript = {
                [string]$state = Test-Path -Path 'C:\Resources\SCCM'
                if($state -eq 'false') {
                    $false
                } else {
                    $true
                }
            }
            GetScript = {
                $sccmSetupFolderExists = Test-Path -Path 'C:\Resources\SCCM'
                @{
                    Result = [string]$sccmSetupFolderExists
                }
            }
            DependsOn = '[File]Resources', '[Script]ConfigMgrSetup'
        }

        Script ConfigMgrSetupIni
        {
            SetScript = { 
                Invoke-Command -ScriptBlock { 
                    Start-BitsTransfer -Source 'https://resourcesrderx1ziwk.blob.core.windows.net/gab/config/ConfigMgrSetup.ini' -Destination 'C:\Resources'
                }
            }
            TestScript = {
                [string]$state = Test-Path -Path 'C:\Resources\ConfigMgrSetup.ini'
                if($state -eq 'false') {
                    $false
                } else {
                    $true
                }
            }
            GetScript = {
                $sccmSetupIniExists = Test-Path -Path 'C:\Resources\ConfigMgrSetup.ini'
                @{
                    Result = [string]$sccmSetupIniExists
                }
            }
            DependsOn = '[File]Resources'
        }

        # Wait for resources on other nodes
        WaitForAll SQLServiceAccount {
            ResourceName = '[Script]SetSQLSvcAccount'
            NodeName = 'SQL1'
            RetryCount = 20
            RetryIntervalSec = 180
        }

        Package InstallConfigMgr
        {
            Ensure = 'Present'
            Name = 'ConfigMgr'
            Path = 'C:\Resources\SCCM\SMSSETUP\BIN\X64\setup.exe'
            ProductId = '969F0E85-ED08-4F10-8239-5AE57F184AC4'
            Arguments = '/script C:\Resources\ConfigMgrSetup.ini'
            ReturnCode = 1
            DependsOn = '[Script]ConfigMgrSetup', '[Script]ConfigMgrSetupIni', '[Package]InstallADK', '[WaitForAll]SQLServiceAccount'
            PsDscRunAsCredential = $(New-Object System.Management.Automation.PSCredential ("CM1\azadmin", $(ConvertTo-SecureString "zxcVBN123$%^" -AsPlainText -Force)))
        }
    } #end SCCM node
}