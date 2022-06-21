# TLS (SSL) PKI for DevOps

This repository helps manage TLS Certificates (PKI) with the OpenSSL toolkit in DEV/TEST environments to mimic external (PROD) X.509 PKI.

The repository is based on the excellent work of the "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

## Create New PKI

- Clone repository

```
git clone https://github.com/kborovik/pki-db.git
```

- Create new PKI DB

```
make new
```

```

######################################################################
# WARNING! - All TLS private keys will be destroyed!
######################################################################

Continue destruction? (yes/no): yes

```

- Set PKI passwords

```
mkdir -p ~/.secrets/pki
```

```
echo "VeryBigPassword" > ~/.secrets/pki/PKI_ROOT_PASSWD
```

```
echo "SimplyBigPassword" > ~/.secrets/pki/PKI_SIGNING_PASSWD
```

```
echo "EasySmallPassword" > ~/.secrets/pki/PKI_SERVER_PASSWD
```

- Update `[ ca_dn ]` information

```
vim etc/root-ca.conf
vim etc/signing-ca.conf
vim etc/server.conf
```

- Create certificate template (`CommonName` and `subjectAltName`)

```
cp env/vault.lab5.ca env/new.host.com
```

```
vim env/new.host.com
```

```
source env/new.host.com
```

- Check settings

```
make
```

```
######################################################################
#
# Settings:
# - PKI_CN  = vault.lab5.ca
# - PKI_SAN = DNS:vault.lab5.ca,IP:127.0.0.1
#
######################################################################
```

- Create new Root, Signing and Host certificate

```
make all
```

- Remove old Git repository

```
rm -rf .git
```

- Create new Git repository

```
git init
git add --all
git commit -m 'new pki-db host.com'
```

## Create New Certificate

- Create server certificate template

```
vim env/vault.lab5.ca
```

```
cat env/vault.lab5.ca
```

```
export PKI_CN=vault.lab5.ca
export PKI_SAN=DNS:vault.lab5.ca,IP:127.0.0.1
```

```
source env/vault.lab5.ca
```

- Check settings

```
make
```

```
######################################################################
#
# Settings:
# - PKI_CN  = vault.lab5.ca
# - PKI_SAN = DNS:vault.lab5.ca,IP:127.0.0.1
#
######################################################################
```

- Create certificate

```
make all
```

```
tree certs/
```

```
certs/
├── ca-certificates.crt
├── vault.lab5.ca.crt
├── vault.lab5.ca.csr
├── vault.lab5.ca.key
└── vault.lab5.ca.p12

0 directories, 5 files
```

## Decrypt Private Key

```
make show-key
```

## View CSR, CRT, P12

```
make show-csr
```

```
make show-crt
```

```
make show-p12
```

# Private Key Algorithm

The TLS certificate private key algorithm can be changed from the default `RSA` to `RSA-PSS`, `ED25519`, `ED448` by setting

```
export pkey_algorithm=ED25519
```

or updating `pkey_algorithm` in Makefile

Note: `ED25519` and `ED448` requires OpenSSL 1.1.1 and higher
