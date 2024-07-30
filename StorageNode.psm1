function New-SNIdentity (
    [Parameter(Mandatory)] [string] $AuthToken
) {
    if (Test-Path ".\identity\identity.cert") { Write-Host "An identity already exists." -ForegroundColor Red; Exit }
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
    Write-Host ("Suggested:  {0}" -f $suggested.version)
    if ($current -ne $suggested.version) {
        Get-Binaries
    }
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

Export-ModuleMember -Function New-SNIdentity, Update-StorageNode
