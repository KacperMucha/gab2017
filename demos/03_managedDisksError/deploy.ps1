$resourceGroupName = 'managed-disk-demo-rg1'
$location = 'West Europe'
$deploymentParameters = @{
    Name = ('managedDiskDemo' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
    ResourceGroupName = $resourceGroupName
    TemplateFile = (Get-Item -Path .\azuredeploy.json)
    Force = $true
    Verbose = $true
}

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
New-AzureRmResourceGroupDeployment @deploymentParameters