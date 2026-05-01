#cloud-config
hostname: ${hostname}

package_update: true
package_upgrade: true

packages:
  - vim
  - nano
  - htop
  - net-tools
  - curl
  - wget
  - git
  - unzip
  - tar
  - iputils-ping
  - traceroute
  - dnsutils
  - telnet
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release
  - jq

runcmd:

runcmd:
  # Azure CLI (must exist first)
  - bash -c "sudo apt-get update -y"
  - bash -c "sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg"

  - bash -c 'curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null'
  - bash -c 'AZ_REPO=$(lsb_release -cs) && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list'

  - bash -c "sudo apt-get update -y"
  - bash -c "sudo apt-get install -y azure-cli"

  # This installs kubectl + kubelogin automatically
  - bash -c "sudo az aks install-cli"

  # verify
  - bash -c "az version >> /var/log/cloud-init-custom.log 2>&1 || true"
  - bash -c "kubectl version --client >> /var/log/cloud-init-custom.log 2>&1 || true"
  - bash -c "kubelogin --version >> /var/log/cloud-init-custom.log 2>&1 || true"

  - echo "Cloud-init completed" >> /var/log/cloud-init-custom.log
  
  