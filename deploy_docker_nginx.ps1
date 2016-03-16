Param(
  [string]$rg_name      = 'DockerNginx',
  [string]$location     = 'West Europe',
  [string]$vnet_cidr    = '10.10.0.0/24',
  [string]$vmname       = 'webserver01',
  [string]$dnsname      = 'greydock'
)

function GenerateParameters ($vmname, $credentials, $addressPrefix, $dnsname, $storageaccountname) {
  @{ "vmname"             = $($vmname);
     "adminUsername"      = $($credentials.Username);
     "adminPassword"      = $($credentials.Password);
     "addressPrefix"      = $($addressPrefix);
     "dnsname"            = $($dnsname);
     "storageaccountname" = $($storageaccountname)
   }
}


Login-AzureRmAccount
$credentials = Get-Credential -Message "Username and Password for the account to be created on the Docker Host"
$storageaccountname = ($rg_name -creplace '[^a-zA-Z0-9]').toLower()

$home_dir = "~\" + $rg_name + "-" + (Get-Date -UFormat %s)
mkdir $home_dir
Set-Location $home_dir
git clone https://github.com/sammy/docker_azure_template.git

$rg_list = Get-AzureRmResourceGroup
$existing_resource_groups = @()
foreach ($rg in $rg_list) { $script:existing_resource_groups += $rg.ResourceGroupName }
if    ($existing_resource_groups.Contains($rg_name)) { Write-Host "Resource Group already exists, skipping creation of" $rg_name  "in"  $rg.Location -foregroundcolor "yellow" }
else  {
  Write-Host "Resource Group $rg_name not found, creating it now" -foregroundcolor "yellow"
  New-AzureRmResourceGroup -Name $rg_name -Location $location -Force
}

$parameters = GenerateParameters $vmname $credentials $vnet_cidr $dnsname $storageaccountname
New-AzureRmResourceGroupDeployment  -Name                     ("$rg_name-" + (Get-Date -UFormat "%A.%d.%m.%Y-%H-%M")) `
                                    -ResourceGroupName        $rg_name `
                                    -TemplateFile             "$home_dir\docker_azure_template\azuredeploy.json" `
                                    -TemplateParameterObject  $parameters


Set-Location ~
Remove-Item -Recurse -Force $home_dir

$publicIP = Get-AzureRMPublicIPAddress -ResourceGroupName $rg_name -Name ($dnsname + "_publicIP")
$url = ('http://' + $publicIP.dnsSettings.FQDN)
$response = Invoke-WebRequest -Uri $url

if ($response.StatusCode = 200) { Start $url }
else { Write-Host "Oops! We received a status code of $($response.StatusCode) while expecting a 200" -foregroundcolor "red" }
