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
  $columns = [System.Collections.Generic.List[string]]@('{{.Names}}', '{{.ID}}', '{{.State}} ({{.Status}})');
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
  $protectedContainers = @("dev.strategic.smithdrug.com", "dev.microservices.smithdrug.com");
  docker container ls -a --filter "status=exited" --format "table {{.Names}}" | Select-Object -Skip 1 | ForEach-Object {
    $containerName = (-split $_)[0];
    If (-not ($protectedContainers -contains $containerName)) {
      docker container rm $containerName;
    }
  }
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
