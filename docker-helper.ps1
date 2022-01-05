function dcls {
    Param(
        [switch] $all,
        [switch] $created,
        [switch] $runningFor,
        [switch] $ports,
        [switch] $mounts,
        [switch] $size,
        [switch] $image,
        [switch] $command
    );
    $allFlag = If ($all) {'--all'} Else {''};
    $columns = [System.Collections.Generic.List[string]]@('{{.Names}}', '{{.ID}}', '{{.Status}}');
    If ($created) {$columns.Add('{{.CreatedAt}}');}
    If ($runningFor) {$columns.Add('{{.RunningFor}}');}
    If ($ports) {$columns.Add('{{.Ports}}');}
    If ($mounts) {$columns.Add('{{.Mounts}}');}
    If ($size) {$columns.Add('{{.Size}}');}
    If ($image) {$columns.Add('{{.Image}}');}
    If ($command) {$columns.Add('{{.Command}}');}
    $formatString = $columns -join '\t';
    docker container ls $allFlag --format "table $formatString";
}

function dils {
    Param([switch] $size, [switch] $digest);
    $columns = [System.Collections.Generic.List[string]]@('{{.Repository}}:{{.Tag}}', '{{.ID}}', '{{.CreatedSince}}');
    If ($size) {$columns.Add('{{.Size}}');}
    If ($digest) {$columns.Add('{{.Digest}}');}
    $formatString = $columns -join '\t';
    docker image ls --format "table $formatString";
}

function dvls {
    Param([switch] $scope, [switch] $mountPoint);
    $columns = [System.Collections.Generic.List[string]]@('{{.Name}}', '{{.Driver}}');
    If ($scope) {$columns.Add('{{.Scope}}');}
    If ($mountPoint) {$columns.Add('{{.Mountpoint}}');}
    $formatString = $columns -join '\t';
    docker volume ls --format "table $formatString";
}

function dcl {
    Param($container);
    docker container logs $container;
}

function dcs {
    Param($container);
    docker container stats $container;
}

function dci {
    Param($container, [switch] $size);
    $sizeFlag = If ($size) {'--size'} Else {''};
    docker container inspect $sizeFlag $container;
}

function dii {
    Param($image);
    docker image inspect $image;
}

function dvi {
    Param($volume);
    docker volume inspect $volume;
}

function dcrm {
    Param($container);
    docker container rm $container;
}

function dirm {
    Param($image);
    docker image rm $image;
}

function dvrm {
    Param($volume);
    docker volume rm $volume;
}

function dcp {
    docker container prune --force;
}

function dip {
    docker image prune --force;
}

function dshell {
    Param($container);
    docker container exec -it $container /bin/bash;
}

function dis {
    Param($container, $outputFile);
    docker image save --output $outputFile;
}

function dil {
    Param($imageFile);
    docker image load --input $imageFile;
}

function dc {
    Param($project, $direction);
    $dockerComposeProjects = (Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json).dockerComposeProjects;
    If ($null -ne $project -and $null -ne $dockerComposeProjects.($project)) {
        $dockerComposeFile = $dockerComposeProjects.($project).composeFile;
        If ('up' -eq $direction) {
            $composeUpCommands = $dockerComposeProjects.($project).composeUpCommands;
            If ($null -ne $composeUpCommands -and $null -ne $composeUpCommands.before) {
                ForEach ($command in $composeUpCommands.before) {
                    Invoke-Expression $command;
                }
            }
            docker-compose --file $dockerComposeFile up -d;
            If ($null -ne $composeUpCommands -and $null -ne $composeUpCommands.after) {
                ForEach ($command in $composeUpCommands.after) {
                    Invoke-Expression $command;
                }
            }
        }
        Elseif ('down' -eq $direction) {
            $composeDownCommands = $dockerComposeProjects.($project).composeDownCommands;
            If ($null -ne $composeDownCommands -and $null -ne $composeDownCommands.before) {
                ForEach ($command in $composeDownCommands.before) {
                    Invoke-Expression $command;
                }
            }
            docker-compose --file $dockerComposeFile down;
            If ($null -ne $composeDownCommands -and $null -ne $composeDownCommands.after) {
                ForEach ($command in $composeDownCommands.after) {
                    Invoke-Expression $command;
                }
            }
        }
        Else {Write-Output 'Invalid direction specified.';}
    }
    Else {Write-Output 'Invalid project specified.';}
}

function dib {
    Param($project, $environment, [switch]$push, [switch]$rmi, [switch]$noCache);
    $config = Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json;
    If ($null -eq $project -or $null -eq $environment) {
        Write-Output 'Please specify both a project and environment.';
    }
    Else {
        $projectConfig = $config.dockerBuildProjects.($project);
        If ($null -eq $projectConfig) {
            Write-Output 'Invalid project specified.';
        }
        Else {
            $tag = $projectConfig.tags.($environment);
            If ($null -eq $tag) {
                Write-Output 'Invalid environment specified.';
            }
            Else {
                $directory = $projectConfig.directory;
                If ($null -eq $directory) {
                    Write-Output 'Invalid config. No project directory specified.';
                }
                Else {
                    $cacheFlag = If ($noCache) {'--no-cache'} Else {''};
                    docker image build $cacheFlag --tag $tag $directory --build-arg APP_ENV=$environment;
                    If ($?) {
                        If ($push) {
                            ForEach ($credential in $config.dockerPushCredentials) {
                                Write-Output $credential.password | docker login $credential.domain --username $credential.username --password-stdin;
                            }
                            docker image push $tag;
                        }
                        If ($rmi) {docker image rm $tag;}
                    }
                }
            }
        }
    }
}

function dhelp {
    Param($command = $null);
    $helpInformation = Get-Content "$PSScriptRoot\help.json" | ConvertFrom-Json;
    If ($null -eq $command) {
        Write-Output "`nDocker Helper is a collection of helper functions for working with Docker.`n";
        $availableCommands = ForEach ($command in $helpInformation.commands.PSObject.Properties) {
            New-Object PSObject -Property @{
                Command = $command.Name
                "Docker Equivalent" = $command.Value.fullDockerCommand
            }
        }
        $availableCommands | Format-Table @{Expression='Command'; Width=10}, "Docker Equivalent";
        Write-Output "`nRun ``dhelp [command]`` for more information about a specific command.`n";
    }
    Else {
        $command = $command.Trim().ToLower();
        $commandInformation = $helpInformation.commands.($command);
        If ($null -eq $commandInformation) {
            Write-Output "`nInvalid command specified: '$command'`n";
        }
        Else {
            Write-Output "`n$($command): $($commandInformation.fullDockerCommand)";
            Write-Output "`nParameters:";
            If ($null -ne $commandInformation.parameters -and $commandInformation.parameters.Count -gt 0) {
                $parameters = ForEach ($parameter in $commandInformation.parameters) {
                    New-Object PSObject -Property @{
                        Name = $parameter.name
                        Description = $parameter.description
                    };
                }
                $parameters | Format-Table @{Expression='Name'; Width=20}, Description;
            }
            Else {Write-Output "`nNone.`n";}
        }
    }
}
