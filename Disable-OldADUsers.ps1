<#
    .SYNOPSIS
    Processes & disables old AD accounts.

    .DESCRIPTION
    When users leave (usually interns) it's important for their AD entries to
    be dealt with properly. They need to be removed from all groups but one,
    the need to be moved to a new OU, and they need to be disabled.

    .PARAMETER Usernames
    Principle username(s) to be specifically processed. Processes all usernames
    in SourceOU otherwise.
    .PARAMETER SourceOU
    OU to look in for usernames to process.
    .PARAMETER Domain
    The AD domain to work in
    .PARAMETER DestinationOU
    OU to place users into after processing.
    .PARAMETER PreservedGroupName
    The group name to preserve removing users from all AD groups.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true,Position=0)]
    [String[]] $Usernames,

    [Parameter(Mandatory=$false,Position=1)]
    [String] $SourceOU = $null,

    [Parameter(Mandatory=$false,Position=2)]
    [String] $Domain = 'some.domain.com',

    [Parameter(Mandatory=$false,Position=3)]
    [String] $DestinationOU = 'Example Destinatino OU',

    [Parameter(Mandatory=$false,Position=4)]
    [String] $PreservedGroupName = 'Example Group Name'
)

Import-Module ActiveDirectory

<#
    .SYNOPSIS
    Creates proper LDAP paths based on given OUs.

    .DESCRIPTION
    Based on the given domain and the OUs given, we need to construct proper
    LDAP paths for querying against AD most effectively.

    .PARAMETER Domain
    The domain we are working in.
    .PARAMETER OU
    The OU to create a path to
#>
function New-OUPath {
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [String] $Domain,

        [Parameter(Mandatory=$false,Position=1)]
        [String] $OU
    )

    if ($OU) { $OUPath = "OU=$SourceOU," }
    foreach ($DC in $($Domain -Split '\.')) {
        $OUPath += "DC=$DC,"
    }
    $OUPath = $OUPath.TrimEnd(',')

    return $OUPath
}

<#
    .SYNOPSIS
    Removes the given AD user from all groups except the given group name.

    .DESCRIPTION
    Before disabling a user from AD, they need to be disassociated from all
    groups they are a part of, save for one of them.

    .PARAMETER ADUser
    The AD user object
    .PARAMETER PreservedGroupName
    The name of the AD group they need to stay in
#>
function Remove-ADUserFromGroups {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [Microsoft.ActiveDirectory.Management.ADUser] $ADUser,

        [Parameter(Mandatory=$true,Position=1)]
        [String] $PreservedGroupName
    )

    # Get all groups the user is a part of
    $ADGroups = Get-ADPrincipalGroupMembership -Identity $ADUser

    # Remove user from each group they're not a part of
    foreach ($ADGroup in $ADGroups) {
        if ($ADGroup.name -ne $PreservedGroupName) {
            $Username = $ADUser.UserPrincipalName
            $GroupName = $ADGroup.name
            if ($PSCmdlet.ShouldProcess("AD Group '$GroupName'", "Remove AD User '$Username'")) {
                Write-Host "`tRemoving from group $($ADGroup.name)"
                Remove-ADGroupMember -Identity $ADGroup -Members $ADUser
            }
        }
    }
}

# First construct the LDAP paths
$SourceOUPath = New-OUPath $Domain $SourceOU
$DestinationOUPath = New-OUPath $Domain $DestinationOU

# Loop through the users
foreach ($Username in $Usernames) {
    $ADUser = Get-ADUser `
        -Filter "UserPrincipalName -like '*$Username*'" `
        -SearchBase $SourceOUPath

    # Make sure the user really does exist
    if (! $ADUser) {
        Write-Warning "User '$Username' not found in domain '$Domain'; Skipping..."
        continue
    }

    Write-Host "Processing user '$Username'..."

    # Remove them from groups
    Remove-ADUserFromGroups $ADUser $PreservedGroupName

    # Move user to new OU
    if ($PSCmdlet.ShouldProcess("OU '$DestinationOU'", "Move AD User '$Username'")) {
        Write-Host "`tMoving user '$Username' to OU '$DestinationOU'"
        Move-ADObject -Identity $ADUser -TargetPath $DestinationOUPath
    }

    # Disable user
    if ($PSCmdlet.ShouldProcess("AD User '$Username'", 'Disable AD User')) {
        Write-Host "`tDisabling user '$Username'"
        Disable-ADAccount -Identity $
    }
}