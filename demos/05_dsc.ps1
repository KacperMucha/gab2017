Get-DSCResource File -syntax

Configuration DeployFile { 
    param (
        [Parameter(Mandatory = $true)]
        [String[]]$Servers,
        [Parameter(Mandatory = $true)]
        [String]$SourceFile,
        [Parameter(Mandatory = $true)]
        [String]$DestinationFile
    )
 
    Node $Servers {
        File Dir {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\Files"
        }

        File CopyFile {
            Ensure = "Present"
            Type = "File"
            SourcePath = $SourceFile
            DestinationPath = $DestinationFile
            DependsOn = "[File]Dir"
        }
    }
}

DeployFile -Servers 'localhost' -SourceFile "C:\Scripts\file1.txt" -DestinationFile "C:\Files\file1.txt" -OutputPath "C:\Scripts\MOF\"
Start-DscConfiguration -Path "C:\Scripts\MOF\" -Wait -Force -Verbose