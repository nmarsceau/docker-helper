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