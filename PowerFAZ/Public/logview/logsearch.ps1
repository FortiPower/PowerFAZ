#
# Copyright 2026, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#


function Add-FAZLogviewLogsearch {

    <#
        .SYNOPSIS
        Add Logview Logsearch

        .DESCRIPTION
        Get id of search

        .EXAMPLE
        Add-FAZLogviewLogsearch

        Add Log Search query

    #>

    Param(
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $uri = "/logview/adom/root/logsearch"

        $_logsearch = new-Object -TypeName PSObject

        $_logsearch | add-member -name "logtype" -membertype NoteProperty -Value "traffic"

        $_device = new-Object -TypeName PSObject

        $_device | add-member -name "devid" -membertype NoteProperty -Value All_FortiGate

        $_logsearch | add-member -name "device" -membertype NoteProperty -Value @($_device)

        $_logsearch | add-member -name "time-order" -membertype NoteProperty -Value "desc"

        $_time = new-Object -TypeName PSObject

        $_time | add-member -name "last-n-hours" -membertype NoteProperty -Value 1

        $_logsearch | add-member -name "time-range" -membertype NoteProperty -Value $_time

        $_logsearch | add-member -name "limit" -membertype NoteProperty -Value 10000

        $tid = Invoke-FAZRestMethod -method "add" -body $_logsearch -jsonrpc "2.0" -uri $uri -connection $connection
        $tid.tid

    }

    End {
    }
}

function Get-FAZLogviewLogsearch {

    <#
        .SYNOPSIS
        Add Logview Logsearch

        .DESCRIPTION
        Get id of search

        .EXAMPLE
        Add-FAZLogviewLogsearch

        Get information about adom

    #>

    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, position = 1)]
        [String]$tid,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $uri = "/logview/adom/root/logsearch/$($tid)"

        Invoke-FAZRestMethod -method "get" -jsonrpc "2.0" -uri $uri -connection $connection

    }

    End {
    }
}
