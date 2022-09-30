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


function Get-DockerBuildProjects {
    $dockerBuildProjects = (Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json).dockerBuildProjects
    $projectNames = foreach ($project in $dockerBuildProjects.PSObject.Properties) {
        New-Object PSObject -Property @{
            "Docker Build Projects" = $project.Name
        }
    }
    if ($projectNames.Length -eq 0) {
        $projectNames += New-Object PSObject -Property @{
            "Docker Build Projects" = ' -- None -- '
        }
    }
    $projectNames | Format-Table "Docker Build Projects"
}


function Invoke-ImageBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [string] $Environment,

        [switch] $Push,
        [switch] $Remove,
        [switch] $NoCache
    )
    if ($Project -eq 'ls' -and $Environment -eq '') {
        Get-DockerBuildProjects
        return
    }
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