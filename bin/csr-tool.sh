#!/bin/bash

csr_name = "my_client.csr"

name = "${1:-my-user}"
csr="${2}"

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${csr_name}
spec:
  groups:
  - system:authenticated
  request: $(cat ${csr} | base64 | tr -d '\n'}
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

echo 
echo "Approving singing request."
kubectl certificate approve ${csr_name}

echo 
echo "Downloading certificate."
kubectl get csr ${csr_name} -o jsonpath='{.status.certificate}' \

