<#
    .SYNOPSIS
    Returns the hostnames of all AD controllers in the given domain.

    .PARAMETER Domain
    The domain to look in for the controllers
#>
function Get-AllADControllers {
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [String] $Domain
    )

    # Get the AD forest
    $Domains = (Get-ADForest -Identity $Domain).Domains

    # Strip out the controllers
    $Controllers = $Domains | Foreach-Object {
        Get-ADDomainController -Filter * -Server $_ | Select-Object -Property HostName
    }

    # Strip off the domain suffix
    $ControllerHostnames = $Controllers | Foreach-Object {
        "$($($_.HostName -Split '\.',2)[0])"
    }

    return $ControllerHostnames
}

Export-ModuleMember -Function Get-AllADControllers
