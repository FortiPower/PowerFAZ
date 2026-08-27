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

        .EXAMPLE
        Add-FAZLogviewLogsearch -filter "srcip == 192.0.2.1 and dstport == 53"

        Add Log Search query with a filter

    #>

    Param(
        [Parameter(Mandatory = $false)]
        [string]$filter,
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

        #add filter
        if ( $PsBoundParameters.ContainsKey('filter') ) {
            $_logsearch | add-member -name "filter" -membertype NoteProperty -Value $filter
        }
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
        Get-FAZLogviewLogsearch -tid XXXXX

        Get Log from tid XXXXX

        .EXAMPLE
        Get-FAZLogviewLogsearch -tid XXXXX -offset 1000

        Get Log from tid XXXXX with offset 1000

        .EXAMPLE
        Get-FAZLogviewLogsearch -tid XXXXX -offset 2000 -limit 500

        Get Log from tid XXXXX with offset 1000 with limit 500

        .EXAMPLE
        Get-FAZLogviewLogsearch -tid XXXXX -onlylog

        Get Log from tid XXXXX and only display log (no metadata)
    #>

    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, position = 1)]
        [String]$tid,
        [Parameter(Mandatory = $false)]
        [int]$limit = 1000,
        [Parameter(Mandatory = $false)]
        [int]$offset = 0,
        [Parameter(Mandatory = $false)]
        [switch]$onlylog,
        [Parameter(Mandatory = $false)]
        [psobject]$connection = $DefaultFAZConnection
    )

    Begin {
    }

    Process {

        $uri = "/logview/adom/root/logsearch/$($tid)"

        $_logsearch = new-Object -TypeName PSObject

        $_logsearch | add-member -name "limit" -membertype NoteProperty -Value $limit
        $_logsearch | add-member -name "offset" -membertype NoteProperty -Value $offset

        $wait = 0
        do {
            #Use exponential backoff for waiting
            $sleeptime = [Math]::Pow(2, $wait)
            Start-Sleep $sleeptime
            $log = Invoke-FAZRestMethod -method "get" -jsonrpc "2.0" -body $_logsearch -uri $uri -connection $connection
            $wait++
            Write-Verbose "Percentage=$($log.percentage), status_code=$($log.status.code), status_message=$($log.status.message)"
        } while ($log.percentage -ne 100)
        Write-Verbose "return-lines=$($log.'return-lines'), total-use-time=$($log.'total-use-time'), total-count=$($log.'total-count'), scanned-logs=$($log.'scanned-logs')"

        #Only display logs
        if ( $PsBoundParameters.ContainsKey('onlylog') ) {
            $log.data
        }
        else {
            $log
        }
    }

    End {
    }
}

function Get-FAZLogviewLogsearchCount {

    <#
        .SYNOPSIS
        Add Logview Logsearch

        .DESCRIPTION
        Get id of search count

        .EXAMPLE
        Get-FAZLogviewLogsearchCount -tid XXXXXX

        Get the total number of logs with the task ID.

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

        $uri = "/logview/adom/root/logsearch/count/$($tid)"

        $count = Invoke-FAZRestMethod -method "get" -jsonrpc "2.0" -uri $uri -connection $connection
        $count
    }

    End {
    }
}
