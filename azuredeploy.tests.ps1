#Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Split-Path -Leaf $here

Describe "Template: $template" -Tags Unit {
    Context "Template Syntax" {
        It "Has a JSON template" {
            "$here\azuredeploy.json" | Should Exist
        }

        It "Has a parameters file" {
            "$here\azuredeploy.parameters.json" | Should Exist
        }

        It "Has a metadata file" {
            "$here\metadata.json" | Should Exist
        }

        It "Converts from JSON and has the expected properties" {
            $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'variables',
                                  'resources',
                                  'outputs'
            $templateProperties = (Get-Content "$here\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | ForEach-Object Name
            $templateProperties | Should Be $expectedProperties
        }

        It "Creates expected Azure resources" {
            $expectedResources = 'VirtualNetwork',
                                 'DomainControllerPublicIpAddress',
                                 'DomainControllerNetworkInterface',
                                 'DomainControllerVirtualMachine',
                                 'DomainControllerDscExtension',
                                 'SqlPublicIpAddress',
                                 'SqlNetworkInterface',
                                 'SqlVirtualMachine',
                                 'SqlDscExtension',
                                 'SccmPublicIpAddress',
                                 'SccmNetworkInterface',
                                 'SccmVirtualMachine',
                                 'SccmDscExtension'
            $templateResources = (Get-Content "$here\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.name
            $templateResources | Should Be $expectedResources
        }
    }
}