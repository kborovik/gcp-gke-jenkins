# About

The repository is the implementation of Jenkins CI/CD in Google Kubernetes Engine (GKE)

# Implemented features

- Jenkins Docker image build (allows linux-users, jenkins-plugin, network proxy, ca-certificate management)
- Jenkins-Agent Docker image build (allows linux-users, jenkins-plugin, network proxy, ca-certificate management)
- Jenkins HELM chart (re-work of official HELM chart)
- Jenkins Configuration as Code (bootstrap a barebone Jenkins instance)
- Jenkins Git SSH Private key as code (part of secret management)
- Jenkins deployment tests:
  - HTTPS connectivity (TLS validation)
  - SSH connectivity (script Jenkins management)
  - Jenkins configuration reload
  - Jenkins restart + running jobs connectivity
  - Jenkins HELM chart re-deployment + running jobs connectivity
- TLS/SSL Cert management (allows secure communication between Jenkins and Jenkins-Agents)
- Secret management (allows administrative isolation between deployment environments)
- GKE Cluster autoscaler

# How to Use

## Set Deployment Target (gke_namespace)

**(Optional)** Export `gke_namespace` variable that represents GKE Namespace. By default `gke_namespace` set to local user name.

```
export gke_namespace="QA"
```

## Create Master password

- Create Master Password (master_key) to encrypt/decrypt deployment secrets

```
mkdir -p ${HOME}/.secrets/jenkins && echo "myBigPassword" > ${HOME}/.secrets/jenkins/${gke_namespace}
```

- Create secrets file

```
touch secrets/${gke_namespace}.enc && sleep 2 && echo "example := record" > secrets/${gke_namespace}.txt && make secrets-encrypt
```

- Git commit secrets file

```
git add secrets/${gke_namespace}.enc && git commit --message='add secrets file'
```

# Jenkins deployment

- To view repository settings

```
make
```

- To build Jenkins Docker images and deploy Jenkins HELM chart

```
make all
```

- To deploy Jenkins HELM chart

```
make helm
```

- To test Jenkins HELM chart

```
make helm-test
```

- To build Jenkins images

```
make docker
```

- To reset development environment

```
make clean
```

For full list of Makefile targets read `Makefile`
