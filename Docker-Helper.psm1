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


function Invoke-ImageLS {
    param(
        [switch] $Size,
        [switch] $Digest
    )
    $columns = @('{{.Repository}}:{{.Tag}}', '{{.ID}}', '{{.CreatedSince}}')
    if ($Size) {$columns += '{{.Size}}'}
    if ($Digest) {$columns += '{{.Digest}}'}
    $formatString = $columns -join '\t'
    docker image ls --format "table $formatString"
}

Set-Alias 'di-ls' Invoke-ImageLS


function Invoke-ImageInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Image
    )
    process {
        docker image inspect $Image
    }
}

Set-Alias 'di-inspect' Invoke-ImageInspect


function Invoke-ImageBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Environment,

        [switch] $Push,
        [switch] $Remove,
        [switch] $NoCache
    )
    $config = Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json
    $projectConfig = $config.dockerBuildProjects.($project)
    if ($null -eq $projectConfig) {
        Write-Output 'Invalid project specified.'
    }
    elseif ($null -eq $projectConfig.tags.($environment)) {
        Write-Output 'Invalid environment specified.'
    }
    elseif ($null -eq $projectConfig.directory) {
        Write-Output 'Invalid config. No project directory specified.'
    }
    else {
        $arguments = @(
            '--tag',
            $projectConfig.tags.($environment),
            '--build-arg',
            "APP_ENV=$environment"
        )
        if ($NoCache) {$arguments += '--no-cache'}
        $arguments += $projectConfig.directory
        docker image build $arguments
        if ($?) {
            if ($Push) {
                foreach ($credential in $config.dockerPushCredentials) {
                    Write-Output $credential.password | docker login $credential.domain --username $credential.username --password-stdin
                }
                docker image push $projectConfig.tags.($environment)
            }
            if ($Remove) {
                docker image rm $projectConfig.tags.($environment)
            }
        }
    }
}

Set-Alias 'di-build' Invoke-ImageBuild


function Invoke-ImagePull {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Image
    )
    docker image pull $Image
}

Set-Alias 'di-pull' Invoke-ImagePull


function Invoke-ImagePush {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Image
    )
    docker image push $Image
}

Set-Alias 'di-push' Invoke-ImagePush


function Invoke-ImageSave {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Image,

        [Parameter(Mandatory = $true)]
        [string] $OutputFile
    )
    docker image save $image --output $OutputFile
}

Set-Alias 'di-save' Invoke-ImageSave


function Invoke-ImageLoad {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $ImageFile
    )
    process {
        docker image load --input $ImageFile
    }
}

Set-Alias 'di-load' Invoke-ImageLoad


function Invoke-ImageRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Image
    )
    process {
        docker image rm $Image
    }
}

Set-Alias 'di-rm' Invoke-ImageRM


function Invoke-ImagePrune {
    docker image prune --force
}

Set-Alias 'di-prune' Invoke-ImagePrune


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


function Invoke-Shell {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Container
    )
    docker container exec -it $Container /bin/bash
}

Set-Alias 'd-shell' Invoke-Shell


function Invoke-DockerCompose {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [ValidateSet('up', 'down')]
        [string] $Direction
    )
    $dockerComposeProjects = (Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json).dockerComposeProjects
    if ($null -ne $dockerComposeProjects.($project)) {
        $arguments = @('--file', $dockerComposeProjects.($project).composeFile)
        if ($null -ne $dockerComposeProjects.($project).envFile) {
            $arguments += '--env-file'
            $arguments += $dockerComposeProjects.($project).envFile
        }
        if ('up' -eq $Direction) {
            $arguments += 'up'
            $arguments += '-d'
        }
        else {
            $arguments += 'down'
        }
        docker-compose $arguments
    }
    else {Write-Output 'Invalid project specified.'}
}

Set-Alias 'd-comp' Invoke-DockerCompose


function Invoke-DockerHelp {
    param(
        [string] $command = $null    
    )
    $helpInformation = Get-Content "$PSScriptRoot\help.json" | ConvertFrom-Json
    if ($null -eq $command) {
        Write-Output "`nDocker Helper is a collection of helper functions for working with Docker.`n"
        $availableCommands = ForEach ($command in $helpInformation.commands.PSObject.Properties) {
            New-Object PSObject -Property @{
                Command = $command.Name
                "Docker Equivalent" = $command.Value.fullDockerCommand
            }
        }
        $availableCommands | Format-Table @{Expression='Command'; Width=10}, "Docker Equivalent"
        Write-Output "`nRun ``d-help [command]`` for more information about a specific command.`n"
    }
    else {
        $command = $command.Trim().ToLower()
        $commandInformation = $helpInformation.commands.($command)
        if ($null -eq $commandInformation) {
            Write-Output "`nInvalid command specified: '$command'`n"
        }
        else {
            Write-Output "`n$($command): $($commandInformation.fullDockerCommand)"
            Write-Output "`nParameters:"
            if ($null -ne $commandInformation.parameters -and $commandInformation.parameters.Count -gt 0) {
                $parameters = foreach ($parameter in $commandInformation.parameters) {
                    New-Object PSObject -Property @{
                        Name = $parameter.name
                        Description = $parameter.description
                    }
                }
                $parameters | Format-Table @{Expression='Name'; Width=20}, Description
            }
            else {Write-Output "`nNone.`n"}
        }
    }
}

Set-Alias "d-help" Invoke-DockerHelp
