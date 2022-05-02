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
    If ($Created) {$columns += '{{.CreatedAt}}'}
    If ($RunningFor) {$columns += '{{.RunningFor}}'}
    If ($Ports) {$columns += '{{.Ports}}'}
    If ($Mounts) {$columns += '{{.Mounts}}'}
    If ($Size) {$columns += '{{.Size}}'}
    If ($Image) {$columns += '{{.Image}}'}
    If ($Command) {$columns += '{{.Command}}'}
    $formatString = $columns -join '\t'
    docker container ls $allFlag --format "table $formatString"
}

Set-Alias 'dc-ls' Invoke-ContainerLS


function Invoke-ContainerInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Container,

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
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Container
    )
    process {
        docker container logs $Container
    }
}

Set-Alias 'dc-logs' Invoke-ContainerLogs


function Invoke-ContainerStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Container
    )
    process {
        docker container stats $Container
    }
}

Set-Alias 'dc-stats' Invoke-ContainerStats


function Invoke-ContainerRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Container
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
    If ($Size) {$columns += '{{.Size}}'}
    If ($Digest) {$columns += '{{.Digest}}'}
    $formatString = $columns -join '\t'
    docker image ls --format "table $formatString"
}

Set-Alias 'di-ls' Invoke-ImageLS


function Invoke-ImageInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Image
    )
    process {
        docker image inspect $Image
    }
}

Set-Alias 'di-inspect' Invoke-ImageInspect


function Invoke-ImageBuild {
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$Environment,

        [switch]$Push,
        [switch]$Remove,
        [switch]$NoCache
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
                docker image push $tag
            }
            if ($Remove) {
                docker image rm $projectConfig.tags.($environment)
            }
        }
    }
}

Set-Alias 'di-build' Invoke-ImageBuild


function Invoke-ImageSave {
    param(
        [Parameter(Mandatory)]
        [string]$Image,

        [Parameter(Mandatory)]
        [string]$OutputFile
    )
    docker image save $image --output $OutputFile
}

Set-Alias 'di-save' Invoke-ImageSave


function Invoke-ImageLoad {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$ImageFile
    )
    process {
        docker image load --input $ImageFile
    }
}

Set-Alias 'di-load' Invoke-ImageLoad


function Invoke-ImageRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Image
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
    If ($Scope) {$columns += '{{.Scope}}'}
    If ($MountPoint) {$columns += '{{.Mountpoint}}'}
    $formatString = $columns -join '\t'
    docker volume ls --format "table $formatString"
}

Set-Alias 'dv-ls' Invoke-VolumeLS


function Invoke-VolumeInspect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Volume
    )
    process {
        docker volume inspect $Volume
    }
}

Set-Alias 'dv-inspect' Invoke-VolumeInspect


function Invoke-VolumeRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Parameter(ValueFromPipeline)]
        [string]$Volume
    )
    process {
        docker volume rm $Volume
    }
}

Set-Alias 'dv-rm' Invoke-VolumeRM


function Invoke-Shell {
    param(
        [Parameter(Mandatory)]
        [string]$Container
    )
    docker container exec -it $Container /bin/bash
}

Set-Alias 'd-shell' Invoke-Shell


function Invoke-DockerCompose {
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [ValidateSet('up', 'down')]
        [string]$Direction
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
        [string]$command = $null    
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
