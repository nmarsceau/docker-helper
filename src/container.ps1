function Invoke-ContainerLS {
    param(
        [switch] $All,
        [switch] $Created,
        [switch] $RunningFor,
        [switch] $Ports,
        [switch] $Mounts,
        [switch] $Size,
        [switch] $Image,
        [switch] $Command
    )
    $allFlag = $all ? '--all' : ''
    $columns = @('{{.Names}}', '{{.ID}}', '{{.Status}}')
    if ($Created) {$columns += '{{.CreatedAt}}'}
    if ($RunningFor) {$columns += '{{.RunningFor}}'}
    if ($Ports) {$columns += '{{.Ports}}'}
    if ($Mounts) {$columns += '{{.Mounts}}'}
    if ($Size) {$columns += '{{.Size}}'}
    if ($Image) {$columns += '{{.Image}}'}
    if ($Command) {$columns += '{{.Command}}'}
    $formatString = $columns -join '\t'
    docker container ls $allFlag --format "table $formatString"
}

Set-Alias 'dc-ls' Invoke-ContainerLS


function Invoke-ContainerStart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container
    )
    process {
        docker container start $Container
    }
}

Set-Alias 'dc-start' Invoke-ContainerStart


function Invoke-ContainerStop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Time = 10
    )
    process {
        docker container stop --time $Time $Container
    }
}

Set-Alias 'dc-stop' Invoke-ContainerStop


function Invoke-ContainerRestart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Time = 10
    )
    process {
        docker container restart --time $Time $Container
    }
}

Set-Alias 'dc-restart' Invoke-ContainerRestart


function Invoke-ContainerInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container,

        [switch] $Size
    )
    begin {
        $sizeFlag = $Size ? '--size' : ''
    }
    process {
        docker container inspect $sizeFlag $Container
    }
}

Set-Alias 'dc-inspect' Invoke-ContainerInspect


function Invoke-ContainerLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container
    )
    process {
        docker container logs $Container
    }
}

Set-Alias 'dc-logs' Invoke-ContainerLogs


function Invoke-ContainerStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container
    )
    process {
        docker container stats $Container
    }
}

Set-Alias 'dc-stats' Invoke-ContainerStats


function Invoke-Shell {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Container
    )
    $hasBash = ($null -ne (docker container exec $Container which bash))
    $shell = $hasBash ? '/bin/bash' : '/bin/sh'
    docker container exec -it $Container $shell
}

Set-Alias 'd-shell' Invoke-Shell


function Invoke-ContainerRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Container
    )
    process {
        docker container rm $Container
    }
}

Set-Alias 'dc-rm' Invoke-ContainerRM


function Invoke-ContainerPrune {
    docker container prune --force
}

Set-Alias 'dc-prune' Invoke-ContainerPrune