function Invoke-VolumeLS {
    param(
        [switch] $Scope,
        [switch] $MountPoint
    )
    $columns = @('{{.Name}}', '{{.Driver}}')
    if ($Scope) {$columns += '{{.Scope}}'}
    if ($MountPoint) {$columns += '{{.Mountpoint}}'}
    $formatString = $columns -join '\t'
    docker volume ls --format "table $formatString"
}

Set-Alias 'dv-ls' Invoke-VolumeLS


function Invoke-VolumeInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Volume
    )
    process {
        docker volume inspect $Volume
    }
}

Set-Alias 'dv-inspect' Invoke-VolumeInspect


function Invoke-VolumeRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Volume
    )
    process {
        docker volume rm $Volume
    }
}

Set-Alias 'dv-rm' Invoke-VolumeRM


function Invoke-VolumePrune {
    docker volume prune --force
}

Set-Alias 'dv-prune' Invoke-VolumePrune