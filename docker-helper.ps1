function dcls {
  Param([switch] $a);
  If ($a) {$_a = '-a';} Else {$_a = '';}
  docker container ls $_a --format "table {{.Names}}\t{{.ID}}\t{{.Status}}";
}

function dils {
  docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}";
}

function dvls {
  docker volume ls --format "table {{.Name}}\t{{.Driver}}";
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
