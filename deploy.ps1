$resourceGroupName = 'sccm-lab-rg1'
$location = 'West Europe'
$deploymentParameters = @{
    Name = ('sccmDeployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
    ResourceGroupName = $resourceGroupName
    TemplateFile = (Get-Item -Path .\azuredeploy.json) 
    TemplateParameterFile = (Get-Item -Path .\azuredeploy.parameters.json) 
    Force = $true
    Verbose = $true
}

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
New-AzureRmResourceGroupDeployment @deploymentParameters
