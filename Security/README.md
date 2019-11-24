# Recommendations

### End-to_end TLS

Vault should always be used with TLS in production. If intermediate load balancers or reverse proxies are used to front Vault, they 
should not terminate TLS. This way traffic is always encrypted in transit to Vault and minimizes risks introduced by intermediate 
layers.

### Single Tenancy

Vault should be the only main process running on a machine. This reduces the risk that another process running on the same machine is 
compromised and can interact with Vault. Similarly, running on bare metal should be preferred to a VM, and a VM preferred to a 
container. This reduces the surface area introduced by additional layers of abstraction and other tenants of the hardware. Both VM 
and container based deployments work, but should be avoided when possible to minimize risk.

### Firewall Traffic

Vault listens on well known ports, use a local firewall to restrict all incoming and outgoing traffic to Vault and essential system 
services like NTP. This includes restricting incoming traffic to permitted subnets and outgoing traffic to services Vault needs to 
connect to, such as databases.

### Disable SSH/ Remote Desktop

When running a Vault as a single tenant application, users should never access the machine directly. Instead, they should access 
Vault through its API over the network. Use a centralized logging and telemetry solution for debugging. Be sure to restrict access to 
logs as need to know.

### Disable SWAP

Vault encrypts data in transit and at rest, however it must still have sensitive data in memory to function. Risk of exposure should 
be minimized by disabling swap to prevent the operating system from paging sensitive data to disk. Vault attempts to "memory lock" to 
physical memory automatically, but disabling swap adds another layer of defense.

### Don't run as root (yeah, lol)

Vault is designed to run as an unprivileged user, and there is no reason to run Vault with root or Administrator privileges, which 
can expose the Vault process memory and allow access to Vault encryption keys. Running Vault as a regular user reduces its privilege. 
Configuration files for Vault should have permissions set to restrict access to only the Vault user.

### Turn off core dumps

A user or administrator that can force a core dump and has access to the resulting file can potentially access Vault encryption keys. 
Preventing core dumps is a platform-specific process; on Linux setting the resource limit `RLIMIT_CORE` to `0` disables core dumps. 
This can be performed by process managers and is also exposed by various shells; in Bash `ulimit -c 0` will accomplish this.


### Immutable Upgrades

Vault relies on an external storage backend for persistence, and this decoupling allows the servers running Vault to be managed 
immutably. When upgrading to new versions, new servers with the upgraded version of Vault are brought online. They are attached to 
the same shared storage backend and unsealed. Then the old servers are destroyed. This reduces the need for remote access and upgrade 
orchestration which may introduce security gaps

### Avoid Root tokens

Vault provides a root token when it is first initialized. This token should be used to setup the system initially, particularly 
setting up auth methods so that users may authenticate. We recommend treating Vault configuration as code, and using version control 
to manage policies. Once setup, the root token should be revoked to eliminate the risk of exposure. Root tokens can be generated when 
needed, and should be revoked as soon as possible.


### Enable auditing

Vault supports several auditing backends. Enabling auditing provides a history of all operations performed by Vault and provides a 
forensics trail in the case of misuse or compromise. Audit logs securely hash any sensitive data, but access should still be 
restricted to prevent any unintended disclosures.

### Upgrade Frequently (But test it too)

Vault is actively developed, and updating frequently is important to incorporate security fixes and any changes in default settings
such as key lengths or cipher suites. Subscribe to the Vault mailing list and GitHub CHANGELOG for updates.

### SELinux / AppArmor

Using additional mechanisms like SELinux and AppArmor can help provide additional layers of security when using Vault. While Vault 
can run on many operating systems, we recommend Linux due to the various security primitives mentioned here.

### Restrict Storage Access

Vault encrypts all data at rest, regardless of which storage backend is used. Although the data is encrypted, an attacker with 
arbitrary control can cause data corruption or loss by modifying or deleting keys. Access to the storage backend should be restricted 
to only Vault to avoid unauthorized access or operations.

### Disable Shell Command History (That's more for sysadmins)

You may want the vault command itself to not appear in history at all. 

### Tweak ulimits

It is possible that your Linux distribution has strict process ulimits. Consider to review ulimits for maximum amount of open files, 
connections, etc. before going into production; they may need increasing.

### Docker Containers

To leverage the "memory lock" feature inside the Vault container you will likely need to use the overlayfs2 or another supporting 
driver.

### No Clear Text Credentials 

The seal stanza of server configuration file configures the seal type to use for additional data protection such as using HSM or 
Cloud KMS solutions to encrypt and decrypt the master key. DO NOT store your cloud credentials or HSM pin in clear text within the 
seal stanza. If the Vault server is hosted on the same cloud platform as the KMS service, use the platform-specific identity 
solutions. If that is not applicable, set the credentials as environment variables (e.g. `VAULT_HSM_PIN`).