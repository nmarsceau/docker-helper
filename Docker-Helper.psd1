#
# Module manifest for module 'Docker-Helper'
#
# Generated by: Nick Marsceau
#
# Generated on: 3/6/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Docker-Helper.psm1'

# Version number of this module.
ModuleVersion = '0.0.1'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = 'cede9f7d-37c0-4e69-a573-ed4ad672d605'

# Author of this module
Author = 'Nick Marsceau'

# Description of the functionality provided by this module
Description = 'Docker Helper is a collection of helper functions for working with Docker.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.1'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Invoke-ContainerLS',
    'Invoke-ContainerStart',
    'Invoke-ContainerStop',
    'Invoke-ContainerRestart',
    'Invoke-ContainerInspect',
    'Invoke-ContainerLogs',
    'Invoke-ContainerStats',
    'Invoke-ContainerRM',
    'Invoke-ContainerPrune',
    'Invoke-ImageLS',
    'Invoke-ImageInspect',
    'Invoke-ImageBuild',
    'Invoke-ImagePull',
    'Invoke-ImagePush',
    'Invoke-ImageSave',
    'Invoke-ImageLoad',
    'Invoke-ImageRM',
    'Invoke-ImagePrune',
    'Invoke-VolumeLS',
    'Invoke-VolumeInspect',
    'Invoke-VolumeRM',
    'Invoke-VolumePrune',
    'Invoke-NetworkLS',
    'Invoke-NetworkRM',
    'Invoke-NetworkPrune',
    'Invoke-Shell',
    'Invoke-DockerCompose',
    'Invoke-DockerHelp'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(
    'dc-ls',
    'dc-start',
    'dc-stop',
    'dc-restart',
    'dc-inspect',
    'dc-logs',
    'dc-stats',
    'dc-rm',
    'dc-prune',
    'di-ls',
    'di-inspect',
    'di-build',
    'di-pull',
    'di-push',
    'di-save',
    'di-load',
    'di-rm',
    'di-prune',
    'dv-ls',
    'dv-inspect',
    'dv-rm',
    'dv-prune',
    'dn-ls',
    'dn-rm',
    'dn-prune',
    'd-shell',
    'd-comp',
    'd-help'
)

# List of all modules packaged with this module
ModuleList = @('Docker-Helper')

# List of all files packaged with this module
FileList = @('.\.gitignore', '.\Docker-Helper.psd1', '.\Docker-Helper.psm1', '.\example-config.json', '.\help.json', '.\LICENSE', '.\README.md')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
        # A URL to the license for this module.
        LicenseUri = 'https://github.com/nmarsceau/docker-helper/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/nmarsceau/docker-helper'
    }
}
}
