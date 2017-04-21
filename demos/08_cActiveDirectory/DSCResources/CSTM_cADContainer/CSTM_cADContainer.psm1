function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ContainerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $TargetResource = $null;

    try {
        $ContainerIdentity = "CN=" + $ContainerName + "," + $Path
        $Container = Get-ADObject -Identity $ContainerIdentity

        $TargetResource = @{
            ContainerName = $Container.Name
            Path = $Container.DistinguishedName.Split(',',2)[1]
            Ensure = 'Absent'
        }
        if ($Container)
        {
            $TargetResource['Ensure'] = 'Present'
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose -Message "AD container $ContainerName was not found"
        $TargetResource = @{
            ContainerName = $ContainerName
            Path = $Path
            Ensure = 'Absent'
        }
    }    
 
    return $TargetResource
} #end function Get-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ContainerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $TargetResource = Get-TargetResource @PSBoundParameters
    $IsCompliant = $true

    if ($Ensure -eq 'Absent')
    {
        if ($targetResource.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Container Ensure property is NOT in the desired state. Expected $($PSBoundParameters.Ensure), actual $($TargetResource.Ensure)."
            $IsCompliant = $false
        }
    }
    else
    {
        foreach ($Parameter in $PSBoundParameters.Keys)
        {
            if ($PSBoundParameters.$Parameter -ne $TargetResource.$Parameter)
            {
                Write-Verbose -Message "Container $Parameter property is NOT in the desired state. Expected $($PSBoundParameters.$Parameter), actual $($targetResource.$Parameter)."
                $IsCompliant = $false
            }
        } #end foreach PSBoundParameter
    }

    if ($IsCompliant)
    {
        Write-Verbose -Message "Active Directory container $ContainerName is in the desired state."
        return $true
    }
    else
    {
        Write-Verbose -Message "Active Directory container $ContainerName is NOT in the desired state."
        return $false
    }
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ContainerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    <# If Ensure is set to "Present" and the website specified in the mandatory input parameters does not exist, then create it using the specified parameter values #>
    <# Else, if Ensure is set to "Present" and the website does exist, then update its properties to match the values provided in the non-mandatory parameter values #>
    <# Else, if Ensure is set to "Absent" and the website does not exist, then do nothing #>
    <# Else, if Ensure is set to "Absent" and the website does exist, then delete the website #>

    $Container = Get-TargetResource @PSBoundParameters
    $ContainerIdentity = "CN=" + $ContainerName + "," + $Path

    if ($Ensure -eq 'Present' -and $Container.Ensure -eq 'Absent') {
        Write-Verbose -Message "Creating container $ContainerName."
        New-ADObject -Type Container -Name $ContainerName -Path $Path
    }
    elseif ($Ensure -eq 'Present' -and $Container.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Container $ContainerName is in desired state. Expected $($PSBoundParameters.Ensure), actual $($Container.Ensure)."
    }
    elseif ($Ensure -eq 'Absent' -and $Container.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Container $ContainerName is in desired state. Expected $($PSBoundParameters.Ensure), actual $($Container.Ensure)."
    }
    elseif ($Ensure -eq 'Absent' -and $Container.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing container $ContainerName."
        Remove-ADObject -Identity $ContainerIdentity -Confirm:$false
    }
} #end function Set-TargetResource