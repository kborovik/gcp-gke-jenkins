.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

SHELL := /bin/bash

###############################################################################
# Software versions
###############################################################################
jenkins_ver := 2.332.3
jenkins_agent_ver := 4.11.2-4
ubuntu_ver := 20.04

###############################################################################
# Dynamic Environment Variables
###############################################################################
gke_namespace ?= $(shell id --user --name)

###############################################################################
# Static Environment Variables
###############################################################################
gcp_project ?= lab5-jenkins-d1
gcp_region ?= us-central1

terraform_dir := $(abspath terraform)
terraform_output_local := $(terraform_dir)/output.json
terraform_output_remote := gs://terraform-$(gcp_project)/jenkins/output.json

gcp_project_config := $(terraform_dir)/$(gcp_project).tfvars

ifneq ($(file < $(terraform_output_local)),)
gcp_region := $(shell jq -r ".google_region.value // empty" $(terraform_output_local))
gke_name := $(shell jq -r ".gke_name.value // empty" $(terraform_output_local))
registry ?= $(gcp_region)-docker.pkg.dev/$(gcp_project)/jenkins-docker
endif

jenkins_img       := $(registry)/jenkins:$(jenkins_ver)-$(gke_namespace)
jenkins_agent_img := $(registry)/jenkins-agent:$(jenkins_agent_ver)-$(gke_namespace)
ubuntu_img        := $(registry)/ubuntu:$(ubuntu_ver)-$(gke_namespace)

###############################################################################
# Secrets VARs
###############################################################################
master_key ?= $(strip $(file < ${HOME}/.secrets/jenkins/${gke_namespace}))

jenkins_dns ?= $(gke_namespace)-jenkins.lab5.gcp
jenkins_ip ?=
admin_user ?= admin
admin_pass ?=
admin_ssh ?=

registry_key := $(shell base64 --wrap=0 ${HOME}/.docker/config.json)
github_ssh_key := $(file < ${HOME}/.ssh/id_rsa)

###############################################################################
# Show settings
###############################################################################
settings: secrets-clean
	$(call header,Settings)
	echo "#"
	echo "# gcp_project       = $(gcp_project)"
	echo "# gke_name          = $(gke_name)"
	echo "# gke_namespace     = $(gke_namespace)"
	echo "#"
	echo "# jenkins_ver       = $(jenkins_ver)"
	echo "# jenkins_agent_ver = $(jenkins_agent_ver)"
	echo "# jenkins_dns       = $(jenkins_dns)"
	echo "# jenkins_ip        = $(jenkins_ip)"
	echo "# admin_user        = $(admin_user)"
	echo "# admin_pass        = $(admin_pass)"
	echo "#"
	echo "# registry          = $(registry)"
	echo "# jenkins_img       = $(jenkins_img)"
	echo "# jenkins_agent_img = $(jenkins_agent_img)"
	echo "#"
	echo "# PKI_SAN           = $(PKI_SAN)"
	echo "#"

###############################################################################
# All
###############################################################################

all: secrets-clean prompt docker ssl helm test

clean: helm-clean docker-clean secrets-clean

###############################################################################
# Secrets. Variable values stored in secrets.enc
###############################################################################
secrets_enc := secrets/$(gke_namespace).enc
secrets_txt := secrets/$(gke_namespace).txt

$(secrets_txt):
	openssl enc -d -aes128 -pbkdf2 -base64 -in $(secrets_enc) -pass pass:$(master_key) -out $@ || shred -uf $(secrets_txt)

$(secrets_enc): $(secrets_txt)
	openssl enc -aes128 -pbkdf2 -base64 -in $(secrets_txt) -pass pass:$(master_key) -out $@ && shred -uf $(secrets_txt)

secrets-decrypt: $(secrets_txt)

secrets-encrypt: $(secrets_enc)

secrets-clean:
	-shred -uf $(secrets_txt)

include $(secrets_txt)

###############################################################################
# Terraform
###############################################################################
terraform: terraform-apply

terraform-fmt: secrets-clean
	$(call header,Checking Terraform Code Formatting)
	cd $(terraform_dir)
	terraform fmt -check

terraform-init: terraform-fmt
	$(call header,Running Terraform Init)
	cd $(terraform_dir)
	terraform init -upgrade -input=false -reconfigure -backend-config="bucket=terraform-${gcp_project}" -backend-config="prefix=ptd-ii"

terraform-plan: terraform-init
	$(call header,Running Terraform Plan)
	cd $(terraform_dir)
	terraform plan -var-file="${google_project_config}" -input=false -refresh=true

terraform-apply: terraform-init
	$(call header,Running Terraform Apply)
	cd $(terraform_dir)
	terraform apply -auto-approve -var-file="${google_project_config}" -input=false -refresh=true && terraform output -json -no-color > ${terraform_output_local}

terraform-show:
	cd $(terraform_dir)
	terraform show

terraform-state:
	cd $(terraform_dir)
	terraform state list

terraform-destory: proxy-down
	cd $(terraform_dir)
	terraform plan -destroy -var-file="${google_project_config}" -compact-warnings -out tfplan.bin -target="google_container_cluster.elastic2"
	terraform apply -destroy tfplan.bin
	rm -rf tfplan.bin

terraform-clean:
	-rm -rf ${terraform_output_local} ${KUBECONFIG} ${terraform_dir}/.terraform.lock.hcl ${terraform_dir}/.terraform

###############################################################################
# Docker
###############################################################################
docker: docker-build-jenkins docker-build-jenkins-agent docker-build-ubuntu docker-build-kaniko secrets-clean

# docker_mount += --mount type=volume,source=kaniko-cache,destination=/cache
docker_mount += --mount type=bind,source=$${HOME}/.docker,destination=/kaniko/.docker
docker_mount += --mount type=bind,source=$$(pwd),destination=/workspace

docker_build_arg += --build-arg=kaniko_ver=$(kaniko_ver)
docker_build_arg += --build-arg=registry_key=$(registry_key)

docker-envsubst: secrets-clean
	envsubst '$${github_ssh_key} $${gke_namespace}' < docker/github-ssh-key.groovy > docker/github-ssh-key.groovy.txt

docker-build-jenkins: docker-envsubst
	$(call header,Build Jenkins Image)
	docker build --build-arg=jenkins_ver=$(jenkins_ver) --tag=$(jenkins_img) --file="docker/Dockerfile.jenkins" .
	docker push $(jenkins_img)

docker-build-jenkins-agent:
	$(call header,Build Jenkins Agent Image)
	docker build --build-arg=jenkins_agent_ver=$(jenkins_agent_ver) --tag=$(jenkins_agent_img) --file="docker/Dockerfile.jenkins-agent" .
	docker push $(jenkins_agent_img)

docker-build-ubuntu:
	$(call header,Build Ubuntu)
	docker build $(docker_build_arg) --tag=$(ubuntu_img) --file="docker/Dockerfile.ubuntu" .
	docker push $(ubuntu_img)

docker-build-kaniko:
	$(call header,Build Kaniko)
	docker build $(docker_build_arg) --tag=$(kaniko_img) --file="docker/Dockerfile.kaniko" .
	docker push $(kaniko_img)

kaniko-build-jenkins-agent:
	docker run --rm $(docker_mount) $(kaniko_img) --cache --cache-repo $(cache_repo) --reproducible --dockerfile docker/Dockerfile.jenkins-agent --destination $(jenkins_agent_img) --verbosity info

docker-clean:
	-docker rmi $(jenkins_img) $(jenkins_agent_img) $(ubuntu_img) $(kaniko_img)
	docker image prune --force
	docker container prune --force

shell-jenkins:
	docker run -it --rm $(jenkins_img) bash

shell-jenkins-k8s:
	kubectl exec --stdin --tty jenkins-0 --container=jenkins -- bash

shell-jenkins-agent:
	docker run -it --rm $(jenkins_agent_img) bash

shell-ubuntu:
	docker run -it --rm $(ubuntu_img) bash

shell-kaniko:
	docker run -it --rm --entrypoint /busybox/sh $(docker_mount) $(kaniko_img)

###############################################################################
# SSL/TLS Certificates
###############################################################################
ssl: ssl-create-jks secrets-clean

ssl_key := pki/certs/$(jenkins_dns).key
ssl_csr := pki/certs/$(jenkins_dns).csr
ssl_crt := pki/certs/$(jenkins_dns).crt
ssl_p12 := pki/certs/$(jenkins_dns).p12
ssl_jks := pki/certs/$(jenkins_dns).jks

ssl_cert := $(ssl_key) $(ssl_csr) $(ssl_crt) $(ssl_p12)

PKI_CN=$(jenkins_dns)
PKI_SAN=DNS:$(jenkins_dns),DNS:jenkins.$(gke_namespace).svc.cluster.local,DNS:jenkins-agent.$(gke_namespace).svc.cluster.local,IP:$(jenkins_ip)

$(ssl_cert):
	cd pki
	$(MAKE) all

$(ssl_jks): $(ssl_cert)
	$(call header,Generate JKS file)
	-rm -f $@
	keytool -importkeystore -srckeystore $(ssl_p12) -srcstoretype PKCS12 -srcstorepass $(master_key) -srcalias $(jenkins_dns) -deststoretype JKS  -deststorepass $(master_key) -destalias $(jenkins_dns) -destkeystore $(ssl_jks) 2>/dev/null

ssl-create-jks: $(ssl_jks)

ssl-show-csr:
	openssl req -text -noout -in $(ssl_csr)

ssl-show-crt:
	openssl x509 -text -noout -in $(ssl_crt)

ssl-show-p12:
	openssl pkcs12 -info -nodes -passin 'pass:$(master_key)' -in $(ssl_p12)

ssl-show-jks:
	keytool -list -storepass $(master_key) -keystore $(ssl_jks) 2>/dev/null

###############################################################################
# GKE Credentials
###############################################################################
gke-credentials: $(KUBECONFIG)
	$(call header,Get GKE Credentials)
	gcloud container clusters get-credentials --zone=$(gcp_region) $(gke_name)
	kubectl config set-context --current --namespace $(gke_namespace)

###############################################################################
# Helm
###############################################################################
helm: helm-deploy secrets-clean

helm_release := jenkins
helm_dir := helm/jenkins

helm_vars += --set registry_key=$(registry_key)
helm_vars += --set controllerImage=$(jenkins_img)
helm_vars += --set agentImage=$(jenkins_agent_img)
helm_vars += --set adminUser=$(admin_user)
helm_vars += --set adminPassword=$(admin_pass)
helm_vars += --set loadBalancerIP=$(jenkins_ip)
helm_vars += --set keyStoreFile=$(shell base64 --wrap=0 $(ssl_jks))
helm_vars += --set keyStorePass=$(master_key)

helm-bootstrap: secrets-clean
	envsubst '$${admin_user} $${admin_pass} $${admin_ssh} $${gke_namespace} $${kaniko_img} $${ubuntu_img} $${jenkins_img} $${jenkins_agent_img} $${jenkins_ip}' < $(helm_dir)/configs/jcasc-default-config.yaml > $(helm_dir)/configs/jcasc-default-config.txt

helm-deploy: helm-bootstrap
	$(call header,Deploy Jenkins HELM Chart)
	helm upgrade $(helm_release) $(helm_dir) --install --create-namespace --namespace ${gke_namespace} ${helm_vars} --wait --timeout=2m --atomic

helm-test: helm-bootstrap
	helm upgrade $(helm_release) $(helm_dir) --install --create-namespace --namespace ${gke_namespace} ${helm_vars} --debug --dry-run

helm-clean:
	-kubectl delete statefulsets jenkins; helm uninstall $(helm_release)

helm-logs:
	$(call header,Wait for Jenkins Pod Get Ready)
	kubectl wait --for=condition=Ready pod/jenkins-0
	$(call header,Show Jenkins Logs)
	kubectl logs --follow --timestamps=false jenkins-0 -c jenkins

helm-restart:
	$(call header,Delete Jenkins Pod)
	kubectl delete pod/jenkins-0
	$(call header,Wait for Jenkins Pod Get Ready)
	kubectl wait  --timeout=90s --for=condition=Ready pod/jenkins-0
	$(call header,Show Jenkins Logs)
	kubectl logs --tail=10 --timestamps=false pod/jenkins-0 -c jenkins

###############################################################################
# Functions
###############################################################################
test: secrets-clean test-jenkins-https test-remove-know-hosts test-reload-jcasc test-add-jenkins-job test-start-jenkins-job test-view-jenkins-job

test-jenkins-https: secrets-clean
	$(call header,Test Jenkins HTTPS Access)
	curl -X GET -I -L https://$(jenkins_ip)/login

test-remove-know-hosts: secrets-clean
	ssh-keygen -f ${HOME}/.ssh/known_hosts -R ${jenkins_ip} >/dev/null

test-reload-jcasc:
	$(call header,Reload Jenkins JCASC Configuration)
	ssh -l admin ${jenkins_ip} reload-jcasc-configuration

test-add-jenkins-job:
	$(call header,Add Jenkins Test Job)
	ssh -l admin ${jenkins_ip} create-job jenkins-test-job < helm/jenkins/configs/jenkins-test-job.xml

test-start-jenkins-job:
	$(call header,Start Jenkins Test Job)
	ssh -l admin ${jenkins_ip} build jenkins-test-job

test-view-jenkins-job:
	$(call header,View Jenkins Test Job)
	ssh -l admin ${jenkins_ip} console jenkins-test-job -f

###############################################################################
# Functions
###############################################################################
define header
echo
echo "########################################################################"
echo "# $(1)"
echo "########################################################################"
endef

########################################################################
# Error Checks
########################################################################
prompt: settings
	echo
	read -p "Continue deployment? (yes/no): " INP
	if [ "$${INP}" != "yes" ]; then 
	  echo "Deployment aborted"
	  exit 100
	fi

ifeq ($(shell which gcloud),)
$(error Missing command 'gcloud'. https://cloud.google.com/sdk/docs/install)
endif

ifeq ($(shell which kubectl),)
$(error Missing command 'kubectl'. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
endif

ifeq ($(shell which helm),)
$(error Missing command 'helm'. https://helm.sh/docs/intro/install/)
endif

ifeq ($(shell which yq),)
$(error Missing command 'yq'. https://github.com/mikefarah/yq/)
endif

ifeq ($(shell which curl),)
$(error Missing command 'curl'. https://curl.se/)
endif

ifeq ($(shell which docker),)
$(error Missing command 'docker'. https://www.docker.com/)
endif

ifeq ($(shell which keytool),)
$(error Missing command 'keytool'. https://www.java.com/)
endif

ifeq ($(strip $(master_key)),)
$(error master_key is not set. Run | mkdir -p ${HOME}/.secrets/jenkins && echo "myBigPassword" > ${HOME}/.secrets/jenkins/${gke_namespace} |)
endif

ifeq ($(wildcard $(secrets_enc)),)
$(error File '$(secrets_enc)' not found. Run | touch $(secrets_enc) && sleep 2 && echo "admin_pass := ''" > $(secrets_txt) && make secrets-encrypt |)
endif

ifeq ($(file < $(gcp_project_config)),)
$(error Missing Terraform GCP Project config $(gcp_project_config))
endif
