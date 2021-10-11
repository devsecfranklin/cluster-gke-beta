# User Setup

Each user gets:

* A dedicated namespace
* A pre-configured amount of CPU and Memory to use.

## Cluster Credentials

```sh
alias k kubectl
gcloud container clusters get-credentials secure-dev-lab --zone us-central1
k config get-clusters
k config set-cluster gke_gcp-gcs-pso_us-central1_secure-dev-lab
k get nodes
```

## Certificates

```sh
go run bin/csr-gen.go client <user-name>;
bin/csr-tool.sh <user-name> client.csr
bin/role.sh <user-name>
```
