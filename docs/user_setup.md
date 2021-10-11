# User Setup

```sh
gcloud container clusters get-credentials secure-dev-lab --zone us-central1
go run bin/csr-gen.go client <user-name>;
bin/csr-tool.sh <user-name> client.csr
bin/role.sh <user-name>
```
