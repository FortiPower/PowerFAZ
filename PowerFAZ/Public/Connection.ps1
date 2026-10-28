#
# Copyright 2026, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Connect-FAZ {

    <#
      .SYNOPSIS
      Connect to a FortiAnalyzer

      .DESCRIPTION
      Connect to a FortiAnalyzer

      .EXAMPLE
      Connect-FAZ -Server 192.0.2.1

      Connect to a FortiAnalyzer with IP 192.0.2.1

      .EXAMPLE
      Connect-FAZ -Server 192.0.2.1 -SkipCertificateCheck

      Connect to a FortiAnalyzer with IP 192.0.2.1 and disable Certificate (chain) check

      .EXAMPLE
      Connect-FAZ -Server 192.0.2.1 -port 4443

      Connect to a FortiAnalyzer using HTTPS (with port 4443) with IP 192.0.2.1 using (Get-)credential

      .EXAMPLE
      $cred = get-credential
      Connect-FAZ -Server 192.0.2.1 -credential $cred

      Connect to a FortiAnalyzer with IP 192.0.2.1 and passing (Get-)credential

      .EXAMPLE
      $mysecpassword = ConvertTo-SecureString mypassword -AsPlainText -Force
      Connect-FAZ -Server 192.0.2.1 -Username manager -Password $mysecpassword

      Connect to a FortiAnalyzer with IP 192.0.2.1 using Username and Password

      .EXAMPLE
      $fw1 = Connect-FAZ -Server 192.0.2.1
      Connect to a FortiAnalyzer with IP 192.0.2.1 and store connection info to $fw1 variable

      .EXAMPLE
      $fw2 = Connect-FAZ -Server 192.0.2.1 -DefaultConnection:$false

      Connect to a FortiAnalyzer with IP 192.0.2.1 and store connection info to $fw2 variable
      and don't store connection on global ($DefaultFAZConnection) variable

  #>

    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [String]$Server,
        [Parameter(Mandatory = $false)]
        [String]$Username,
        [Parameter(Mandatory = $false)]
        [SecureString]$Password,
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $false)]
        [switch]$SkipCertificateCheck = $false,
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$port,
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 0,
        [Parameter(Mandatory = $false)]
        [string]$adom = "root",
        [Parameter(Mandatory = $false)]
        [boolean]$DefaultConnection = $true
    )

    Begin {
    }

    Process {

        $connection = @{server = ""; session = ""; websession = ""; port = ""; headers = ""; invokeParams = ""; adom = ""; version = "" ; id = 0 }

        $invokeParams = @{DisableKeepAlive = $false; UseBasicParsing = $true; SkipCertificateCheck = $SkipCertificateCheck; TimeoutSec = $Timeout }

        if ("Desktop" -eq $PSVersionTable.PsEdition) {
            #Remove -SkipCertificateCheck from Invoke Parameter (not supported <= PS 5)
            $invokeParams.remove("SkipCertificateCheck")
        }
        else {
            #Core Edition
            #Remove -UseBasicParsing (Enable by default with PowerShell 6/Core)
            $invokeParams.remove("UseBasicParsing")
        }

        if (!$port) {
            $port = 443
        }

        #for PowerShell (<=) 5 (Desktop), Enable TLS 1.1, 1.2 and Disable SSL chain trust (needed/recommanded by FortiAnalyzer)
        if ("Desktop" -eq $PSVersionTable.PsEdition) {
            #Enable TLS 1.1 and 1.2
            Set-FAZCipherSSL
            if ($SkipCertificateCheck) {
                #Disable SSL chain trust...
                Set-FAZuntrustedSSL
            }
        }

        $uri = "https://${Server}:${port}/jsonrpc"

        #If there is a password (and a user), create a credential
        if ($Password) {
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
        }
        #Not Credential (and no password)
        if ($null -eq $Credential) {
            $Credential = Get-Credential -Message 'Please enter administrative credential for your FortiAnalyzer'
        }

        $postParams = @{
            id      = $connection.id++
            method  = "exec"
            verbose = 1
            session = $null
            params  = @(
                @{
                    data = @{
                        user   = $Credential.username;
                        passwd = $Credential.GetNetworkCredential().Password;
                    }
                    url  = 'sys/login/user'
                }
            )
        }

        try {
            $irmResponse = Invoke-RestMethod $uri -Method POST -Body ($postParams | ConvertTo-Json -Depth 10) -SessionVariable FAZ @invokeParams
        }
        catch {
            Show-FAZException $_
            throw "Unable to connect to FortiAnalyzer"
        }

        #
        if ($irmResponse.result.status.code -ne "0") {
            throw "Unable to connect to FortiAnalyzer (" + $irmResponse.result.status.code + ") " + $irmResponse.result.status.message
        }

        $connection.server = $server
        $connection.session = $irmResponse.session
        $connection.websession = $FAZ
        $connection.headers = $headers
        $connection.port = $port
        $connection.invokeParams = $invokeParams
        $connection.adom = $adom

        #get FAZ version
        $status = Invoke-FAZRestMethod sys/status -connection $connection
        $connection.version = [version]"$($status.major).$($status.minor).$($status.patch)"

        if ( $DefaultConnection ) {
            Set-Variable -name DefaultFAZConnection -value $connection -scope Global
        }

        $connection
    }

    End {
    }
}

function Set-FAZConnection {

    <#
        .SYNOPSIS
        Configure FAZ connection Setting

        .DESCRIPTION
        Configure FAZ connection Setting (ADOM...)

        .EXAMPLE
        Set-FAZConnection -adom MyAdom

        Configure default connection adom to MyAdom

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$adom,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        if ($PSCmdlet.ShouldProcess($connection.server, 'Set default adom on connection')) {
            $connection.adom = $adom
        }

    }

    End {
    }
}

function Disconnect-FAZ {

    <#
        .SYNOPSIS
        Disconnect a FortiAnalyzer

        .DESCRIPTION
        Disconnect the connection of FortiAnalyzer

        .EXAMPLE
        Disconnect-FAZ

        Disconnect the connection

        .EXAMPLE
        Disconnect-FAZ -confirm:$false

        Disconnect the connection with no confirmation

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $url = "sys/logout"

        if ($PSCmdlet.ShouldProcess($connection.server, 'Proceed with removal of FortiAnalyzer connection ?')) {
            $null = Invoke-FAZRestMethod -method "exec" -uri $url -connection $connection
            if (Test-Path variable:global:DefaultFAZConnection) {
                Remove-Variable -name DefaultFAZConnection -scope global
            }
        }
    }

    End {
    }
}