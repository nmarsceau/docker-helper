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
