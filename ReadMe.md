#Docker deployment to Azure

This script will deploy the following components to MS Azure Cloud using ARM.
The idea was for the script to require minimum user input, so that human error is minimized, and so that it could be fully integrated with other processes, but also give the ability to override default values.

+ One Resource Group
+ One Storage account
+ One VNET
+ One Subnet
+ One Public IP
+ One Network Interface
+ One Ubuntu VM with Docker configured
+ One NSG
+ A custom script to configure an NGINX container on the docker host

_Certain conventions are used in the script, which will be explained in each components section below_

## Prerequisites
+ MS Azure Powershell
+ git

##Examples
Execute with default values:
```Powershell
./deploy_docker_nginx.ps1
```

Override defaults values:
```Powershell
./deploy_docker_nginx.ps1 -rg_name    Test `
                          -vmname     mywebserver `
                          -location   "West US" `  
                          -vnet_cidr  "192.168.100.0/24" `
                          -dnsname    mynginxapplication
```

##Resource group
By default a resource group with the name DockerNginx will be deployed in West Europe location.
The name can be overriden by ```-rg_name``` parameter and the location by ```-location``` parameter

<strong>The script will deploy all components in the same location as the resource group as a convention</strong>

##Storage account
The storage account is deployed in the same location as the resource group.
The name of the storage account will be derived from the name of the resource group, but any special characters will be removed to comply with naming rules of Azure.

##Virtual Network
By default, the script will deploy a VNet with a CIDR block of 10.10.0.0/24. This can be overriden by ```-vnet_cidr```.
The VNet will be deployed with the following naming convention ```{Resourcegroupname}_Vnet```

##Subnet
The subnet will also be created to cover the full VNet CIDR block, so in a default deployment that would also be 10.10.0.0/24
The Subnet will be created with the following naming convention ```{Resourcegroupname}_Subnet```

##Public IP
By default the script will assign the following DNS name to the public IP it deploys: greydock. This can be overriden by the ```-dnsname``` parameter.
The public ip naming convention is ```{dnsname}_PublicIP```

##Ubuntu Server and Network Interface
The server that is deployed is an Ubuntu 14.04, size D1, named by default as webserver01. The server name can be overriden by the ```-vmname``` parameter.
_Currently the script does not allow for customization of the server size or OS version, but the deployment template supports it, so it is just a matter of configuring the extra parameters and constructing them properly in the parameters hashtable._
The Azure Docker extension is also applied to the VM so that it gets automatically configured with Docker.

The network card follows the following naming convention ```{vmname}_nic``` and the public IP is attached to it. Its private IP is configured dynamically.

##NSG
The NSG is configured to allow traffic only on port 80, where the NGINX server is listening, and is applied on the subnet level.

##Custom script
The custom script is pulled from a separate github repo here: https://github.com/sammy/docker_azure_custom_script/blob/master/nginx_up.sh
The script will create a Dockerfile, build a docker nginx image with some static content (pulling a github repo with static files), starting up the container, mapping port 80 of the container to port 80 of the host.

###Top level workflow
+ Prompt user for Azure account credentials
+ Prompt user for VM username and Password
+ Set the Scene (create a temp folder and pull the ARM template from a github repo)
+ Create a Resource Group
+ Apply the ARM template
+ Cleanup the temp folder
+ Check if the website is reachable
+ Fire up a browser and navigate to the website

###Final thoughts / considerations

+ Currently input is required by the user for credentials. For the Azure login this could be eliminated by setting up certificate authentication. For the VM credentials, default credentials could be provided in the script and template but that would be a security concern as those would be in clear text. Providing them in clear text could be an option if a configuration management tool ensured those are changed post deployment.

+ For a production situation it would be preferred that the Vnet is split in two subnets, to model a DMZ - Trusted scenario. A load balancer would then be placed in the DMZ and it would handle all communications. The trusted subnet should only allow traffic from the load balancer on specific ports. This would also cater for horizontal scalability and high availability and we could execute the same script with a different ```-vmname``` parameter to add vm's to the load balancer.

<a href="http://armviz.io/#/?load=https://raw.githubusercontent.com/sammy/docker_template/master/azuredeploy.json" target="_blank">
  <img src="http://armviz.io/visualizebutton.png"/>
</a>
