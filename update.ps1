function Main {
    $current = Get-FileVersion -File storagenode.exe
    $latest = Get-LatestStorageNodeVersion
    Write-Host ("Current: {0}" -f $current)
    Write-Host ("Latest:  {0}" -f $latest.version)
    if($current -ne $latest.version) {
        Update-Executable
    }
}

function Update-Executable {
    $ServiceName = Get-Content servicename.txt
    Stop-Service $ServiceName
    Remove-Item storagenode.exe
    Start-BitsTransfer ($latest.url -replace '{os}', 'windows' -replace '{arch}', 'amd64') storagenode.zip
    Expand-Archive storagenode.zip .
    Remove-Item storagenode.zip
    Start-Service $ServiceName
}

function Get-FileVersion ($File = 'storagenode.exe') {
    $v = (Get-Item $File).VersionInfo.FileVersionRaw
    "{0}.{1}.{2}" -f $v.Major, $v.Minor, $v.Build
}

function Get-LatestStorageNodeVersion {
    $version = Invoke-RestMethod https://version.storj.io
    $version.processes.storagenode.suggested
}

Push-Location (Split-Path $MyInvocation.MyCommand.Path)
Main
Pop-Location
