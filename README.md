

# PowerFAZ

**PowerFAZ** is an open-source PowerShell module for interacting with Fortinet FortiAnalyzer through its JSON REST API.

With PowerFAZ, you can retrieve ADOM and device information, search logs and send custom API requests.

## Features

The current release (v1.0.0) includes:

- [dvmdb](#dvmdb) (Get Adom and device from dvmdb)
- [Logview](#logview) (Add logview search and get results)

There is some extra feature
- [Invoke API](#invoke-api)
- [ADOM](#ADOM)
- [Multi Connection](#multiconnection)

More functionality will be added later.

## Compatibility

PowerFAZ has been tested with FortiAnalyzer 7.x and 8.x.

## Requirements

- Windows PowerShell 5.1 or PowerShell 6/7 (PowerShell Core). The latest supported version is recommended.
- A FortiAnalyzer appliance or instance.
- HTTPS access to the FortiAnalyzer.
- A FortiAnalyzer administrator account with JSON API access enabled.

## Instructions

Install PowerFAZ from the PowerShell Gallery:

```powershell
# Automated installation (Powershell 5 or later):
    Install-Module PowerFAZ

# Import the module
    Import-Module PowerFAZ

# Get commands in the module
    Get-Command -Module PowerFAZ

# Get help
    Get-Help Get-FAZDvmdbAdom -Full
```

## Usage

### Connect to FortiAnalyzer

PowerFAZ supports two authentication methods:

- REST API administrator token (recommended).
- Username and password, with JSON API access enabled for the administrator account.

#### Create a REST API Admin Token (recommended)
The first thing to do is to create a REST API Admin token

Go on WebGUI of your FortiAnalyzer, on System Settings  
![](./Medias/FAZ_Home.png)  

Go `Administrators`  
![](./Medias/FAZ_Admin.PNG)  

Click on `Create New` => `REST API Admin`   

![](./Medias/FAZ_New_Admin_API_Rest.png)  
Create the administrator account and configure the following settings:
   - Enable **JSON API Access** and select **Read** or **Read-Write**, depending on the operations you need.
   - Set the appropriate **Admin Profile** (the original example uses **Standard User**).
   - Configure **Trusted IPv4 Hosts** to include the host or network from which PowerFAZ will connect.

Select **OK**. Copy the generated token and store it securely.

![](./Medias/FAZ_New_Admin_API_Rest_regenerate.png)  

Use the token to connect:

```powershell
# Connect to the FortiAnalyzer
    Connect-FAZ 192.0.2.1 -apitoken ytib37ceu5ktmt5p1napi7djwagyxjs5

```
if you get a warning about `Unable to connect` Look [Troubleshooting](#Troubleshooting)

#### Create (or Modify) an administrator with API JSON Access
You can also create (or modify) an administrator with API (JSON) Access  

Go on WebGUI of your FortiAnalyzer, on System Settings  
![](./Medias/FAZ_Home.png)  

Go `Administrators`  
![](./Medias/FAZ_Admin.PNG)  

Click on `Create New` => `Administrator`   

![](./Medias/FAZ_New_Admin_API.PNG)  
and Create or edit the administrator account. 
   -Enable **JSON API Access** and select **Read** or **Read-Write**,
   -  depending on the operations you need. Configure the appropriate **Admin Profile**.

After enabling JSON API access, connect to FortiAnalyzer with the command `Connect-FAZ` :

```powershell
# Connect to the FortiAnalyzer
    Connect-FAZ 192.0.2.1

#we get a prompt for credential
    Please enter administrative credential for your FortiAnalyzer
    User: api
    Password for user api: *****************

```
if you get a warning about `Unable to connect` Look [Troubleshooting](#Troubleshooting)

### dvmdb

You can get info about ADOM `Get-FAZDvmdbAdom` and Device `Get-FAZDvmdbDevice` via dvmdb

#### Retrieve ADOM names

```powershell
# get name of all adom
    Get-FAZDvmdbAdom | select name

    name
    ----
    FortiAnalyzer
    FortiAuthenticator
    FortiCache
    FortiCarrier
    FortiClient
    FortiDDoS
    FortiDeceptor
    FortiFirewall
    FortiFirewallCarrier
    FortiMail
    FortiManager
    FortiProxy
    FortiSandbox
    FortiWeb
    Syslog
    Unmanaged_Devices
    others
    root
```

#### Retrieve devices

```powershell
# get device of all adom

    Get-FAZDvmdbDevice

    adm_pass             : {ENC, [...]}
    adm_usr              :
    app_ver              :
    auto_mgmt            :
    av_ver               :
    beta                 : -1
    branch_pt            : 2902
    build                : 2902
    checksum             :
    cluster_worker       : {}
    conf_status          : unknown
    conn_mode            : active
    conn_status          : UNKNOWN
    [..]
    ip                   : 10.0.255.1
    [...]
    name                 : XXXXXXXX-HA_FG120G
    [...]
    platform_str         : FortiGate-120G
    [...]
    sn                   : FG120GTK2600XXXX
    [...]

```
### LogView

You can search FortiAnalyzer logs using the following cmdlets:

- `Add-FAZLogviewLogsearch` – Create a log search and return its task ID (`tid`).
- `Get-FAZLogviewLogsearchCount` – Retrieve search statistics and monitor progress.
- `Get-FAZLogviewLogsearch` – Retrieve matching log entries.

Start by creating a search with `Add-FAZLogviewLogsearch`. Use the returned `tid` with the other cmdlets.

#### Create a search
```powershell
# build filter for get all DNS log to 8.8.8.8
    Add-FAZLogviewLogsearch -dstip 8.8.8.8 -dstport 53
    1052639461
#You get a number (tid => 1052639461) and you need to use for other cmdlet
```
#### Monitor search progress

Use `Get-FAZLogviewLogsearchCount` with the task ID to retrieve the search statistics:

```powershell
#for get number of log use Get-FAZLogviewLogsearchCount with tid

    Get-FAZLogviewLogsearchCount -tid 1052639461

    total-logs           : 583446
    scanned-logs         : 249837
    matched-logs         : 8497
    elapsed-time-ms      : 1
    estimated-remain-sec : 0
    progress-percent     : 0
    status               : @{code=0; message=succeeded}

#Run the command again to check the progress. Wait until `progress-percent` reaches `100` before retrieving the results:
    Get-FAZLogviewLogsearchCount -tid 1052639461
    total-logs           : 623553
    scanned-logs         : 583047
    matched-logs         : 20227
    elapsed-time-ms      : 118
    estimated-remain-sec : 0
    progress-percent     : 100
    status               : @{code=0; message=succeeded}

```

#### Retrieve log entries

Once the search is complete, retrieve the matching log entries:

```powershell

#You can fetch log now
    Get-FAZLogviewLogsearch -tid 1052639461

    percentage     : 100
    return-lines   : 1000
    total-use-time : 118
    total-count    : 20227
    scanned-logs   : 583047
    data           : {@{date=2026-11-04; time=16:40:39; id=7704187090031870014; itime=2026-11-04 16:40:39; euid=3;
                    epid=1040; dsteuid=1025; dstepid=101; logflag=1; logver=704122902; type=traffic; subtype=forward;
                    level=notice; action=accept; policyid=2; sessionid=1267344202; srcip=192.2.0.1; dstip=8.8.8.8;
                    srcport=52593; dstport=53; trandisp=noop; duration=180; proto=17; sentbyte=90; rcvdbyte=211;
                    sentpkt=1; rcvdpkt=1; logid=0000000013; dstunauthuser=xxxxxxxx; service=DNS; app=DNS;
                    appcat=Network.Service; srcintfrole=lan; dstintfrole=lan; srcserver=0; dstserver=0; appid=16195;
                    apprisk=elevated; policytype=policy; eventtime=1793770838471759208;
                    poluuid=0c1317a6-af54-51f0-1bc5-2e60bbc5fb0d; srcmac=00:50:56:80:e7:69;
                    mastersrcmac=00:50:56:80:e7:69; dstmac=1e:d1:18:24:e7:cd; masterdstmac=1e:d1:18:24:e7:cd;
                    srchwvendor=VMware; srchwversion=Virtual Machine; srcfamily=Virtual Machine; srcswversion=10/11;
                    dstswversion=10/11; devtype=Server; dstdevtype=Router; osname=Windows; dstosname=Windows;
                    srccountry=Reserved; dstcountry=United%20States; srcintf=A-TRK-V1030; dstintf=VDL-DC-ROOT;
                    dstunauthusersource=kerberos; applist=g-default; policyname=DNS; tz=+0100;
                    devid=FG120GTK2600XXX; vd=MyVDOM; dtime=2026-11-04 16:40:39; itime_t=1793770839;
                    devname=POWERFAZ-HA_FG120G},}
                    [...]
    status         : @{code=0; message=succeeded}
    tid            : 1052639461

    #You can only display data using -data parameter
    #the cmdlet return 1000 lines by 1000 lines (max on FAZ API), you need to use -offset to get more log to 

    #for fetch next 1000

    Get-FAZLogviewLogsearch -tid 1052639461 -offset 1000

    percentage     : 100
    return-lines   : 1000
    total-use-time : 773
    total-count    : 8598
    scanned-logs   : 250000
    data           : @{...}
    status         : @{code=0; message=succeeded}
    tid            : 1052639461

    #the cmdlet always retry to get log (can need multiple second to get log) to get more verbose you can use $informationPreference = 'continue'

    $informationPreference = 'continue'
    Get-FAZLogviewLogsearch -tid 1052639461 -offset 2000

    Percentage=0, status_code=0, status_message=succeeded
    Percentage=100, status_code=0, status_message=succeeded
    return-lines=1000, total-use-time=583, total-count=8598, scanned-logs=250000

    percentage     : 100
    return-lines   : 1000
    total-use-time : 583
    total-count    : 8598
    scanned-logs   : 250000
    data           : @{...}
    status         : @{code=0; message=succeeded}
    tid            : 1052639461
```

### Invoke the REST API
for example to get FortiAnalyzer System Status Info

```powershell
# get FortiAnalyzer System Status using API

    Invoke-FAZRestMethod -method "get" sys/status

    Admin Domain Configuration  : Disabled
    BIOS version                : 04000002
    Branch Point                : 3737
    Build                       : 3737
    Current Time                : Fri Oct 30 12:37:09 CET 2026
    Daylight Time Saving        : Yes
    Disk Usage                  : Free 241.50GB, Total 491.08GB
    FIPS Mode                   : Disabled
    Hostname                    : FortiAnalyzer
    License Status              : Valid
    Major                       : 7
    Max Number of Admin Domains : 2
    Minor                       : 6
    Patch                       : 7
    Platform Full Name          : FortiAnalyzer-VM64
    Platform Type               : FAZVM64
    Release Version Information :  (GA.M)
    Serial Number               : FAZ-VMTM21000000
    TZ                          : Europe/Brussels
    Time Zone                   : (GMT+1:00) Brussels, Copenhagen, Madrid, Paris.
    Version                     : v7.6.7-build3737 260601 (GA.M)
    x86-64 Applications         : Yes

```
You can look `FortiAnalyzer - JSON API (Full Reference)` available on [Fortinet Developer Network (FNDN)](https://fndn.fortinet.net/)

### ADOM

it is possible set ADOM when connect to FortiAnalyzer (by default it is on root adom)

For connect on the pester vdom 
```powershell
    Connect-FAZ 192.0.2.1 -adom pester
[...]
```
You can also change default adom using
```powershell
    Set-FAZConnection -adom vdomY
[...]
```

### MultiConnection

it is possible to connect on same times to multi FortiAnalyzer (or same Analyzer with different adom)
You need to use -connection parameter to cmdlet

For example to get adom of 2 FortiAnalyzer

```powershell
# Connect to first FortiAnalyzer
    $faz1 = Connect-FAZ 192.0.2.1 -SkipCertificateCheck -DefaultConnection:$false

#DefaultConnection set to false is not mandatory but only don't set the connection info on global variable

# Connect to second FortiAnalyzer
    $faz2 = Connect-FAZ 192.0.2.2 -SkipCertificateCheck -DefaultConnection:$false

# Get Device (dvmdb) for first FortiAnalyzer
    Get-FAZDvmdbDevice -connection $faz1 | select name, sn, platform_str, ip

    name               sn               platform_str   ip
    ----               --               ------------   --
    XXXXXXXX-HA_FG120G FG120GTK2600XXXX FortiGate-120G 10.0.255.1
[..]
....

# Get Device (dvmdb) for second FortiAnalyzer
    Get-FAZDvmdbDevice -connection $faz2 | select name, sn, platform_str, ip

    name               sn               platform_str   ip
    ----               --               ------------   --
    YYYYYYYY-HA_FG90G  FG90GTK2600YYYY FortiGate-90G 10.0.255.2
...

#Each cmdlet can use -connection parameter

```

### Disconnecting

```powershell
# Disconnect from the FortiAnalyzer
    Disconnect-FAZ
```

## Troubleshooting

### Unable to connect (certificate)

if you use `Connect-FAZ` and get `Unable to Connect (certificate)`

The issue coming from use Self-Signed or Expired Certificate for FortiAnalyzer  
Try to connect using `Connect-FAZ -SkipCertificateCheck`

## How to contribute

Contribution and feature requests are more than welcome. Please use the following methods:

  * For bugs and [issues](https://github.com/FortiPower/PowerFAZ/issues), please use the [issues](https://github.com/FortiPower/PowerFAZ/issues) register with details of the problem.
  * For Feature Requests, please use the [issues](https://github.com/FortiPower/PowerFAZ/issues) register with details of what's required.
  * For code contribution (bug fixes, or feature request), please request fork PowerFAZ, create a feature/fix branch, add tests if needed then submit a pull request.

## Contact

Currently, [@alagoutte](#author) started this project and will keep maintaining it. Reach out to me via [Social Network](#author), Email (see top of file) or the [issues](https://github.com/FortiPower/PowerFAZ/issues) Page here on GitHub. If you want to contribute, also get in touch with me.

## List of available command
```powershell
Add-FAZLogviewLogsearch
Connect-FAZ
Disconnect-FAZ
Get-FAZDvmdbAdom
Get-FAZDvmdbDevice
Get-FAZLogviewLogsearch
Get-FAZLogviewLogsearchCount
Invoke-FAZRestMethod
Set-FAZCipherSSL
Set-FAZConnection
Set-FAZUntrustedSSL
Show-FAZException
```

## Author

**Alexis La Goutte**
- <https://github.com/alagoutte>
- <https://bsky.app/profile/alagoutte.bsky.social>
- <https://twitter.com/alagoutte>
- <https://www.linkedin.com/in/alexis-lagoutte>

## Special Thanks

- Warren F. for his [blog post](http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/) 'Building a Powershell module'
- Erwan Quelin for help about Powershell

## License

Copyright 2026 Alexis La Goutte and the community.
