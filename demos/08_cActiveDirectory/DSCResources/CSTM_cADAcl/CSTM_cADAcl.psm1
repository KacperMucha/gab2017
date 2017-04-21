function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentityReference,

        [Parameter(Mandatory)]
        [ValidateSet("CreateChild", "Delete", "DeleteChild", "DeleteTree", "ExtendedRight", "GenericAll", "GenericExecute", "GenericRead", "GenericWrite", "ListChildren", "ListObject", "ReadControl", "ReadProperty", "Self", "Synchronize", "WriteDacl", "WriteOwner", "WriteProperty")]
        [ValidateNotNullOrEmpty()]
        [string[]]$ActiveDirectoryRight,

        [Parameter(Mandatory)]
        [ValidateSet("Allow", "Deny")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessControlType,

        [Parameter(Mandatory)]
        [ValidateSet("All", "Children", "Descendents", "None", "SelfAndChildren")]
        [ValidateNotNullOrEmpty()]
        [string]$ActiveDirectorySecurityInheritance
    )

    $AclResource = $null;

    try {
        $ObjectPath = "AD:" + $Path
        $Acl = Get-Acl -Path $ObjectPath -ErrorAction Stop
        $Ace = $Acl.Access | Where-Object { 
            $_.IdentityReference -match $IdentityReference -and
            $_.ActiveDirectoryRights -eq $ActiveDirectoryRight -and
            $_.AccessControlType -eq $AccessControlType -and
            $_.InheritanceType -eq $ActiveDirectorySecurityInheritance
        }

        if ($Ace)
        {
            $AclResource = @{
                Path = $Acl.Path.Split('/',4)[3]
                IdentityReference = $Ace.IdentityReference
                ActiveDirectoryRight = $Ace.ActiveDirectoryRights
                AccessControlType = $Ace.AccessControlType
                ActiveDirectorySecurityInheritance = $Ace.InheritanceType
                Ensure = 'Present'
            }
        }
        else
        {
            $AclResource = @{
                Path = $Path
                IdentityReference = $IdentityReference
                ActiveDirectoryRight = $ActiveDirectoryRight
                AccessControlType = $AccessControlType
                ActiveDirectorySecurityInheritance = $ActiveDirectorySecurityInheritance
                Ensure = 'Absent'
            }
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Verbose -Message "Object $Path was not found. Cannot retrieve ACL."
        $AclResource = @{
            Path = $Path
            IdentityReference = $IdentityReference
            ActiveDirectoryRight = $ActiveDirectoryRight
            AccessControlType = $AccessControlType
            ActiveDirectorySecurityInheritance = $ActiveDirectorySecurityInheritance
            Ensure = 'Absent'
        }
    }    
 
    return $AclResource
} #end function Get-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentityReference,

        [Parameter(Mandatory)]
        [ValidateSet("CreateChild", "Delete", "DeleteChild", "DeleteTree", "ExtendedRight", "GenericAll", "GenericExecute", "GenericRead", "GenericWrite", "ListChildren", "ListObject", "ReadControl", "ReadProperty", "Self", "Synchronize", "WriteDacl", "WriteOwner", "WriteProperty")]
        [ValidateNotNullOrEmpty()]
        [string[]]$ActiveDirectoryRight,

        [Parameter(Mandatory)]
        [ValidateSet("Allow", "Deny")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessControlType,

        [Parameter(Mandatory)]
        [ValidateSet("All", "Children", "Descendents", "None", "SelfAndChildren")]
        [ValidateNotNullOrEmpty()]
        [string]$ActiveDirectorySecurityInheritance
    )

    $AclResource = Get-TargetResource @PSBoundParameters
    $IsCompliant = $true

    foreach ($Parameter in $PSBoundParameters.Keys)
    {
        if ($PSBoundParameters.$Parameter -ne $AclResource.$Parameter)
        {
            Write-Verbose -Message "Acl $Parameter property is NOT in the desired state. Expected $($PSBoundParameters.$Parameter), actual $($AclResource.$Parameter)."
            $IsCompliant = $false
        }
    } #end foreach PSBoundParameter

    if($IsCompliant)
    {
        Write-Verbose -Message "Acl object $Path is in the desired state."
    }
    else
    {
        Write-Verbose -Message "Acl object $Path is NOT in the desired state."
    }

    return $IsCompliant
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentityReference,

        [Parameter(Mandatory)]
        [ValidateSet("CreateChild", "Delete", "DeleteChild", "DeleteTree", "ExtendedRight", "GenericAll", "GenericExecute", "GenericRead", "GenericWrite", "ListChildren", "ListObject", "ReadControl", "ReadProperty", "Self", "Synchronize", "WriteDacl", "WriteOwner", "WriteProperty")]
        [ValidateNotNullOrEmpty()]
        [string[]]$ActiveDirectoryRight,

        [Parameter(Mandatory)]
        [ValidateSet("Allow", "Deny")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessControlType,

        [Parameter(Mandatory)]
        [ValidateSet("All", "Children", "Descendents", "None", "SelfAndChildren")]
        [ValidateNotNullOrEmpty()]
        [string]$ActiveDirectorySecurityInheritance
    )

    <# If Ensure is set to "Present" and the website specified in the mandatory input parameters does not exist, then create it using the specified parameter values #>
    <# Else, if Ensure is set to "Present" and the website does exist, then update its properties to match the values provided in the non-mandatory parameter values #>
    <# Else, if Ensure is set to "Absent" and the website does not exist, then do nothing #>
    <# Else, if Ensure is set to "Absent" and the website does exist, then delete the website #>

    $AclResource = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Present' -and $AclResource.Ensure -eq 'Absent') {
        Write-Verbose -Message "Creating acl $Path."
        try 
        {
            $ObjectPath = "AD:" + $Path
            $Acl = Get-Acl -Path $ObjectPath -ErrorAction Stop
            $AdObject = Get-ADObject -LDAPFilter "(&(name=$IdentityReference)(|(objectClass=computer)(objectClass=user)(objectClass=group)))" -Properties objectSid
            $Sid = [System.Security.Principal.SecurityIdentifier] $AdObject.objectSid

            # Create a new access control entry to allow access to the OU
            $Adr = [System.DirectoryServices.ActiveDirectoryRights]$ActiveDirectoryRight
            $Act = [System.Security.AccessControl.AccessControlType]$AccessControlType
            $Adsi = [System.DirectoryServices.ActiveDirectorySecurityInheritance]$ActiveDirectorySecurityInheritance
            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Sid, $Adr, $Act, $Adsi
            # Add the ACE to the ACL, then set the ACL to save the changes
            $Acl.AddAccessRule($Ace)
            Set-Acl -AclObject $Acl $ObjectPath
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose -Message "Object $Path was not found. Cannot create ACL for non-existent object."
        }
    }
    elseif ($Ensure -eq 'Present' -and $AclResource.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Acl $Path is in desired state. Expected $($PSBoundParameters.Ensure), actual $($AclResource.Ensure)."
    }
    elseif ($Ensure -eq 'Absent' -and $AclResource.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Acl $Path is in desired state. Expected $($PSBoundParameters.Ensure), actual $($AclResource.Ensure)."
    }
    elseif ($Ensure -eq 'Absent' -and $AclResource.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing acl $Path."
        try
        {
            $ObjectPath = "AD:" + $Path
            $Acl = Get-Acl -Path $ObjectPath -ErrorAction Stop
            $Ace = $Acl.Access | Where-Object { 
                $_.IdentityReference -match $IdentityReference -and
                $_.ActiveDirectoryRights -eq $ActiveDirectoryRight -and
                $_.AccessControlType -eq $AccessControlType -and
                $_.InheritanceType -eq $ActiveDirectorySecurityInheritance
            }

            Write-Verbose -Message "Ace: $Ace"
            $Acl.RemoveAccessRule($Ace)
            Set-Acl -AclObject $Acl $ObjectPath
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
            Write-Verbose -Message "Object $Path was not found. Cannot remove ACL from non-existent object."
        }
    }
} #end function Set-TargetResource