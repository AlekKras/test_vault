# HashiCorp Tutorial

This is a recommendation on how to spin up HashiCorp in one's environment taking into consideration that
there is no knowledge of one's system nor infrastructure.

## Method 1: Vagrant [Extreme and Manual]

While not knowing what the infrastructure is, one may assume that the system is pretty linear to 
installing the VirtualBox and Vagrant to be able to write Vagrantfile.

### Prerequisites:

- [Vagrant](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Instructions

1) Install the prerequisites. This will work on any system (FreeBSD, *Unix like, and Windows as well)
2) Run (in folder `/Method1`):

```
vagrant up
```
3) Your VirtualBox will create a Vagrantfile that will have a Virtual System ready for you.

### Comments

There are many ways how to provision and configure an easily accessible developement Vault cluster.
This option is great to do in `dev` mode. This single node is provisioned into a local VM. Since it's 
running in `dev` mode, all data is in-memory and not persisted to disk. If any agent fails or the node restarts, all data will be lost. This is only mean for local use.

## Method 2: Ansible [Mediocre]

This method is *Unix focused. It will not work for Windows environments. Assuming that you care about your data integrity, you 
would not want to use Windows anyways, so this method is more beneficial for you.