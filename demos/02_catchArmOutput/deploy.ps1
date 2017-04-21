$resourceGroupName = 'output-demo-rg1'
$location = 'West Europe'
$deploymentParameters = @{
    Name = ('outputDemo' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
    ResourceGroupName = $resourceGroupName
    TemplateFile = (Get-Item -Path .\azuredeploy.json)
    Force = $true
    Verbose = $true
}

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
$deployment = New-AzureRmResourceGroupDeployment @deploymentParameters
$randomString = $deployment.Outputs.GetEnumerator() | Where-Object {$_.Key -eq 'randomString'} | ForEach-Object {$_.Value.Value}
Write-Output "Random string value: $randomString"