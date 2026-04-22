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

runcmd:
  - echo "Cloud-init execution completed" >> /var/log/cloud-init-custom.log