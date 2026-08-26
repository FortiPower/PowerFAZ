#
# Copyright 2026, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#


function Get-FAZDvmdbAdom {

    <#
        .SYNOPSIS
        Get dvmdb ADOM

        .DESCRIPTION
        ADOM table, most attributes are read-only and can only be changed internally.

        .EXAMPLE
        Get-FAZdvmdbadom

        Get information about adom

        .EXAMPLE
        Get-FAZdvmdbadom -adom root

        Get only information of adom root

    #>

    Param(
        [Parameter(Mandatory = $false, position = 1)]
        [String]$adom,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $url = "dvmdb/adom"
        $method = "get"

        if ( $PsBoundParameters.ContainsKey('adom') ) {
            $url += "/" + $adom
        }

        Invoke-FAZRestMethod -method $method -uri $url -connection $connection

    }

    End {
    }
}
