function Get-DockerComposeProjects {
    $dockerComposeProjects = (Get-Content "$PSScriptRoot\..\config.json" | ConvertFrom-Json).dockerComposeProjects
    $projectNames = foreach ($project in $dockerComposeProjects.PSObject.Properties) {
        New-Object PSObject -Property @{
            "Docker Compose Projects" = $project.Name
        }
    }
    if ($projectNames.Length -eq 0) {
        $projectNames += New-Object PSObject -Property @{
            "Docker Compose Projects" = ' -- None -- '
        }
    }
    $projectNames | Format-Table "Docker Compose Projects"
}


function Invoke-DockerCompose {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [string] $Direction
    )
    if ($Project -eq 'ls' -and $Direction -eq '') {
        Get-DockerComposeProjects
        return
    }
    if ('up' -ne $Direction -and 'down' -ne $Direction) {
        Write-Output 'Invalid direction specified.'
        return
    }
    $dockerComposeProjects = (Get-Content "$PSScriptRoot\..\config.json" | ConvertFrom-Json).dockerComposeProjects
    if ($null -eq $dockerComposeProjects.($project)) {
        Write-Output 'Invalid project specified.'
        return
    }
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
    docker compose $arguments
}

Set-Alias 'd-c' Invoke-DockerCompose