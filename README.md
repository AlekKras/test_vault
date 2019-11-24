# HashiCorp Tutorial

This is a recommendation on how to spin up HashiCorp in one's environment taking into consideration that
there is no knowledge of one's system nor infrastructure.

Out of the box solutions that are already offered by the Open-Source community are:
- [`ansible-vault`](https://github.com/brianshumate/ansible-vault)
- [`vaultron`](https://github.com/brianshumate/vaultron)

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

Make sure that you have Ansible installed and run the commands to install Hashicorp Vault.

## Method 3: Kubernetes on GCP [Okayish]

It should be run on GCS. 

Here are the steps:

```
./scripts/install_vault.sh
```

This will verify GPS signatures and checksums from the download. The installation will be in `~/bin`.

```
./scripts/enalbe_services.sh
```

This will enable required services. This will be pretty restrictive yet GCP Security is another aspect of how one can harden that
but for the purpose of running Vault, this will suffice. GCP's Security is out of scope.

```
./scripts/storage.sh
```
Since Vault requires a storage backend to persist its data, it doesn't automatically create the storage bucket, so we need to create 
it. The bucket name is `${PROJECT}-vault-storage`. For security purposes, it's not recommended that other applications or services
have access to this bucket. Even though data is encrypted at rest, it's best to limit the scope as much as you can.

```
./scripts/kms.sh
```
Vault will use KMS to encrypt its unseal keys for auto-unsealing and auto-scaling purposes. 

```
./scripts/iam.sh
```
We are creating the limited and dedicated service account that only has the required permissions. The following is the set of permissions:
- read/write to the Cloud Storage bucket created above;
- encrypt/decrypt data with the KMS key created above
- generate new service accounts


```
./scripts/k8s_public_ip_certs.sh
```

Here we are creating GKE Cluster. We are running that in a dedicated cluster and a dedicated project. Vault
acts as aservice with an IP/DNS entry that other projets and services query. Then we attach a regional public IP 
address. Later on, we will create a reserved IP address to Kubernetes load balancer.  We use regional IP address 
instead of a global IP address because global ones perform load balancing at L7 where regional do it at L4.
Ideally, we don't want the load balancer to perform TLS termination and let Vault manage TLS. It's best to let Vault
manage TLS and thus use an L4 load balancer. Then we are creating TLS certificates. For this repo, I just did the 
Self-signed, but later on you can use Let's Encrypt and/or a trusted CA.

```
./scripts/config.sh
```
We create a config map and secrets to store our data for our pods. The insecure data are places in a configmap.
The secure data is put  in a Kubernetes secret.

```
./scripts/deploy.sh
```
Here we deploy Vault and Load Balancer. We use StatefulSet on  Kubernetes to guarantee:
- exacrtly one service starts at a time. This is required by the vault-inti sidecar service;
- consistent naming for referencing the Vault servers
Load balancer forwards from the IP address reserved in the previous scripts to the pods we just created. The load balancer
listens on port 443 and forwards to port 8200 on the containers.

** Thing to add: Firewall rules in the production **

```
./scripts/comms.sh
```
Configuration of our local Vault CLI to communicate with newly created Vault servers through the Load Balancer.

To check if everything is fine, run 

```
vault status
```

```
./scripts/kv.sh
```
Here we enable KV secrets engine, create a policy to read data, and store a static username/password.

You can try reading the data back by:

```
vault kv get kv/myapp/config
```

You can also curl it like this: 

```
curl -k -H "x-vault-token:${VAULT_TOKEN}" "${VAULT_ADDR}/v1/kv/myapp/config"
```

### Method 4: Docker [Alright]

The config files for consul and vault are in `config/` folder. 

Get a consul master token:
```
$ uuidgen
>>> SECRET_MASTER_TOKEN
```
Replace the master token in `config/consul.json` file.

Then start Consul:
```
docker-compose up -d consul
```

Navigate to `localhost:9500` and ensure ConsulUI is running.

Navigate to `ACL` and output your `SECRET_MASTER_TOKEN`.

Go to New Policy and put name as `vault_agent` and put the rules:
```
{
  "key_prefix": {
    "vault/": {
      "policy": "write"
    }
  },
  "node_prefix": {
    "": {
      "policy": "write"
    }
  },
  "service": {
    "vault": {
      "policy": "write"
    }
  },
  "agent_prefix": {
    "": {
      "policy": "write"
    }
    
  },
  "session_prefix": {
    "": {
      "policy": "write"
    }
  }
}
```

Then generate token for Vault: `ACL` -> `New Token` -> `vault_agent` policy applied

Get that token and replace `config/vault.json` as `VAULT_AGNET_TOKEN` variable.

Start Vault by `docker-compose up -d vault`. Navigate to `localhost:9500`.

Vault has started but not yet initialized.

Let's build vault client:

```
docker-compose build
docker-compose up -d client
```

You can docker exec to the container, initialize it and unseal the vault.

Get list of keys by curl:

```
export VAULT_TOKEN={TOKEN}
export VAULT_ADDR=http://127.0.0.1:9200
curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request LIST \
  "$VAULT_ADDR/v1/kv"
```

Get data from key:

```
export VAULT_TOKEN={TOKEN}
export VAULT_ADDR=http://127.0.0.1:9200
curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/kv/my-secret"
```

