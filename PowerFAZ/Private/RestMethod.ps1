#
# Copyright 2026, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#

function Invoke-FAZRestMethod {

    <#
      .SYNOPSIS
      Invoke RestMethod with FAZ connection (internal) variable

      .DESCRIPTION
      Invoke RestMethod with FAZ connection variable (session)

      .EXAMPLE
      Invoke-FAZRestMethod -method "get" -uri "pm/config/adom/root/obj/firewall/address"

      Invoke-RestMethod with FAZ connection for get pm/config/adom/root/obj/firewall/address uri

    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    Param(
        [Parameter(Mandatory = $true, position = 1)]
        [String]$uri,
        [Parameter(Mandatory = $false)]
        [ValidateSet("get", "set", "add", "update", "delete", "clone", "exec", IgnoreCase = $false)]
        [String]$method = "get",
        [Parameter(Mandatory = $false)]
        [ValidateSet("2.0", IgnoreCase = $false)]
        [String]$jsonrpc,
        [Parameter(Mandatory = $false)]
        [psobject]$body,
        [Parameter(Mandatory = $false)]
        [psobject]$connection
    )

    Begin {
    }

    Process {

        if ($null -eq $connection ) {
            if ($null -eq $DefaultFAZConnection) {
                Throw "Not Connected. Connect to the FortiAnalyzer with Connect-FAZ"
            }
            $connection = $DefaultFAZConnection
        }

        $Server = $connection.Server
        $port = $connection.port
        $headers = $connection.headers
        $invokeParams = $connection.invokeParams
        $sessionvariable = $connection.websession

        $fullurl = "https://${Server}:${port}/jsonrpc"
        $url = $uri

        #Use jsonrpc 2.0 query
        if ( $PsBoundParameters.ContainsKey('jsonrpc') ) {
            #Make Invoke-RestMethod body query

            #No $body ?
            if (-not $body) {
                $body = new-Object -TypeName PSObject
            }
            #Add uri and apiver to body...
            $body | add-member -name "url" -membertype NoteProperty -Value $uri
            $body | add-member -name "apiver" -membertype NoteProperty -Value 3

            $irm_body = @{
                id      = $connection.id++
                method  = $method
                session = $connection.session
                params  = @($body)
                jsonrpc = "2.0"
            }
        }
        else {
            #Make params data (with uri, data, filter...)
            $params = @{
                url = $url
            }
            if ($body) {
                $params.data = $body
            }

            #Make Invoke-RestMethod body query
            $irm_body = @{
                id      = $connection.id++
                method  = $method
                session = $connection.session
                verbose = 1
                params  = @($params)
            }
        }

        try {
            Write-Verbose -message ($irm_body | ConvertTo-Json -Depth 10)

            $response = Invoke-RestMethod $fullurl -Method "POST" -body ($irm_body | ConvertTo-Json -Depth 10 -Compress) -Headers $headers -WebSession $sessionvariable @invokeParams
        }

        catch {
            Show-FAZException $_
            throw "Unable to use FortiAnalyzer API"
        }

        #Use jsonrpc 2.0 query
        if ( $PsBoundParameters.ContainsKey('jsonrpc') ) {
            #Check response code
            if ($response.error) {
                throw "Unable to use FortiAnalyzer API (" + $response.error.code + ") " + $response.error.message
            }
            $response.result
        }
        else {

            #Check status code
            if ($response.result.status.code -ne "0") {
                throw "Unable to use FortiAnalyzer API (" + $response.result.status.code + ") " + $response.result.status.message
            }
            $response.result.data
        }


    }

}