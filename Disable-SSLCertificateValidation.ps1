<#
    .SYNOPSIS
    Disables SSL Certificate validation

    .DESCRIPTION
    Powershell doesn't seem to have a good way to ignore SSL cert validation
    when making a web request. It's essentially just a .NET hook.

    .LINK
    https://blog.ukotic.net/2017/08/15/could-not-establish-trust-relationship-for-the-ssltls-invoke-webrequest/
#>

if (! ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                    delegate
                    (
                        Object obj,
                        X509Certificate certificate,
                        X509Chain chain,
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}

[ServerCertificateValidationCallback]::Ignore()