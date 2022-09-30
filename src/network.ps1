function Invoke-NetworkLS {
    param(
        [switch] $IPv6,
        [switch] $Internal
    )
    $columns = @('{{.ID}}', '{{.Name}}', '{{.Driver}}', '{{.Scope}}')
    if ($IPv6) {$columns += '{{.IPv6}}'}
    if ($Internal) {$columns += '{{.Internal}}'}
    $formatString = $columns -join '\t'
    docker network ls --format "table $formatString"
}

Set-Alias 'dn-ls' Invoke-NetworkLS


function Invoke-NetworkInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Network
    )
    process {
        docker network inspect $Network
    }
}

Set-Alias 'dn-inspect' Invoke-NetworkInspect


function Invoke-NetworkRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Network
    )
    process {
        docker network rm $Network
    }
}

Set-Alias 'dn-rm' Invoke-NetworkRM


function Invoke-NetworkPrune {
    docker network prune --force
}

Set-Alias 'dn-prune' Invoke-NetworkPrune