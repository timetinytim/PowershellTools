<#
    .SYNOPSIS
    Creates a web auth header manually.

    .DESCRIPTION
    There is the occasional site where using 'Invoke-WebRequest -Credential'
    doesn't work because of how -Credential is implemented. This manually
    constructs an authentication header that the website will understand.

    .LINK
    https://stackoverflow.com/questions/27951561/use-invoke-webrequest-with-a-username-and-password-for-basic-authentication-on-t
#>

$user = 'user'
$pass = 'pass'

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

return $Headers
