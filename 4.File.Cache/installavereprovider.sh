#!/bin/bash -e

latestVersion = $(curl -s https://api.github.com/repos/Azure/Avere/releases/latest | jq -r .tag_name)
providerDownloadUrl = "https://github.com/Azure/Avere/releases/download/$latestVersion/terraform-provider-avere"
#localDirectory = "~/.terraform.d/plugins/registry.terraform.io/hashicorp/avere/${latestVersion:1}/linux_amd64"
localDirectory = "~/.terraform.d/plugins/registry.terraform.io/hashicorp/avere/${latestVersion:1}/linux_amd64"
mkdir -p $localDirectory
cd $localDirectory
curl -L $providerDownloadUrl -o terraform-provider-avere_$latestVersion
chmod 755 terraform-provider-avere_$latestVersion
