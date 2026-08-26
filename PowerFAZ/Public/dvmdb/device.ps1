#
# Copyright 2026, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#


function Get-FAZDvmdbDevice {

    <#
        .SYNOPSIS
        Get dvmdb Device

        .DESCRIPTION
        Device table, most attributes are read-only and can only be changed internally

        .EXAMPLE
        Get-FAZDvmdbDevice

        Get information about adom

        .EXAMPLE
        Get-FAZDvmdbDevice -device MyDevice

        Get only information of device MyDevice

        .EXAMPLE
        Get-FAZDvmdbDevice -device MyDevice -vdom MyVdom

        Get only information of device MyDevice with vdom MyVdom
    #>

    Param(
        [Parameter(Mandatory = $false, position = 1)]
        [String]$device,
        [Parameter(Mandatory = $false, position = 2)]
        [String]$vdom,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $url = "dvmdb/device"
        $method = "get"

        if ( $PsBoundParameters.ContainsKey('device') ) {
            $url += "/" + $device

            #Not a mistake, you add only vdom when there is a device...
            if ( $PsBoundParameters.ContainsKey('vdom') ) {
                $url += "/vdom/" + $vdom
            }
        }

        Invoke-FAZRestMethod -method $method -uri $url -connection $connection

    }

    End {
    }
}
