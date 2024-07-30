function New-SNIdentity (
    [Parameter(Mandatory)] [string] $AuthToken
) {
    if (Test-Path ".\identity\identity.cert") {
        Write-Host "An identity already exists." -ForegroundColor Red
        Exit
    }
    if (-not (Test-Path identity.exe)) { Get-Binaries }
    $id = "identity{0}" -f (Get-Date -Format "yyMMddHHmmss")
    Invoke-Expression ".\identity.exe create $id"
    Invoke-Expression ".\identity.exe authorize $id $AuthToken"
    Move-Item -Path "$env:APPDATA\Storj\Identity\$id" -Destination ".\identity"
}

function Update-StorageNode {
    $current = Get-CurrentVersion
    $suggested = Get-SuggestedReleaseVersion
    Write-Host ("Current: {0}" -f $current)
    Write-Host ("Suggested: {0}" -f $suggested.version)
    if ($current -ne $suggested.version) {
        $ServiceName = Get-ServiceName
        if ($ServiceName) {
            Stop-Service -Name $ServiceName
            (Get-Service $ServiceName).WaitForStatus('Stopped')
            Get-Binaries
            Start-Service -Name $ServiceName
        }
        else {
            Get-Binaries
        }
    }
}

function Set-Configuration {
    # Checks
    if (-not (Test-Path ".\identity\identity.cert")) {
        Write-Host "Create an identity first (New-SNIdentity)." -ForegroundColor Red
        Exit
    }
    if (Test-Path "config.yaml") {
        Write-Host "Already configured, a 'config.yaml' already exists." -ForegroundColor Red
        Exit
    }

    # Input
    $Email = Read-Host "E-mail address"
    $Wallet = Read-Host "Wallet address"
    [System.Windows.Forms.SendKeys]::SendWait("28967")
    $ServerPort = Read-Host "Server port"
    [System.Windows.Forms.SendKeys]::SendWait("mydomain.com:28967")
    $ExternalAddress = Read-Host "External address"
    [System.Windows.Forms.SendKeys]::SendWait("14002")
    $ConsolePort = Read-Host "Console port"
    [System.Windows.Forms.SendKeys]::SendWait("7778")
    $PrivatePort = Read-Host "Private port"
    [System.Windows.Forms.SendKeys]::SendWait("1.0 TB")
    $DiskSpace = Read-Host "Disk space"
    Write-Host
    $Answer = Read-Host "Are above settings correct? [Y/n]"
    if (-not ([string]::IsNullOrEmpty($Answer) -or $Answer -eq "y")) {
        Exit
    }

    # Configure
    if (-not (Test-Path "storagenode.exe")) { Get-Binaries }
    $Cmd = "& .\storagenode.exe setup "
    $Cmd += "--console.address :$ConsolePort "
    $Cmd += "--server.address :$ServerPort "
    $Cmd += "--server.private-address 127.0.0.1:$PrivatePort "
    $Cmd += "--contact.external-address $ExternalAddress "
    $Cmd += "--operator.email $Email "
    $Cmd += "--operator.wallet $Wallet "
    $Cmd += "--storage.allocated-disk-space `"$DiskSpace`" "
    $Cmd += "--config-dir `"$PWD`" "
    $Cmd += "--identity-dir `"$PWD\identity`" "
    $Cmd += "--storage.path `"$PWD\storage`" "
    $Cmd += "--log.level warn "
    $Cmd += "--log.output `"$PWD\storagenode.log`" "
    Write-Host
    if (Test-Path .\storagenode.log) { Remove-Item .\storagenode.log }
    Invoke-Expression $Cmd
    if (Test-Path .\storagenode.log) { Get-Content .\storagenode.log | Write-Host -ForegroundColor Red }
}

function Get-Binaries {
    $StorageNodeBinaryURL = (Get-SuggestedReleaseVersion).url
    Start-BitsTransfer -Source $StorageNodeBinaryURL -Destination storagenode.zip
    Expand-Archive -Path storagenode.zip -DestinationPath . -Force
    Remove-Item -Path storagenode.zip
    $IdentityBinaryURL = $StorageNodeBinaryURL -replace '/storagenode_', '/identity_'
    Start-BitsTransfer -Source $IdentityBinaryURL -Destination identity.zip
    Expand-Archive -Path identity.zip -DestinationPath . -Force
    Remove-Item -Path identity.zip
}

function Get-CurrentVersion {
    if (-not (Test-Path storagenode.exe)) { return "0" }
    $v = (Get-Item storagenode.exe).VersionInfo.FileVersionRaw
    "{0}.{1}.{2}" -f $v.Major, $v.Minor, $v.Build
}

function Get-SuggestedReleaseVersion {
    $manifest = Invoke-RestMethod https://version.storj.io
    $version = $manifest.processes.storagenode.suggested
    $version.url = $version.url -replace '{os}', 'windows' -replace '{arch}', 'amd64'
    $version
}

function Get-ServiceName {
    $ExeFullPath = (Get-ChildItem .\storagenode.exe).FullName
    $RegServicesPath = "HKLM:\SYSTEM\CurrentControlSet\Services"
    $ServiceName = @(
        (Get-ChildItem $RegServicesPath -Recurse -ErrorAction SilentlyContinue | 
        Get-ItemProperty | 
        Where-Object { $_ -like "*$ExeFullPath*" }).PSChildName
    )
    if ($ServiceName.Count -ne 1) { return $false }
    $ServiceName
}

Export-ModuleMember -Function New-SNIdentity, Update-StorageNode, Set-Configuration
