# Tekton

## Install `pass`

Store credentials in "pass" manager.

```sh
gpg --list-keys # get your public key id
pass init C25565E4701F4ED36A0711AA114F3606EFD923BB # id of your public GPG key
pass insert gh-username
pass ls
pass insert gh-password
pass ls
pass show gh-username
pass show gh-password
bin/create_secret.sh
```

## Create Secret

```sh
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl get namespace tekton-pipelines
# you can wait to see it RUNNING
watch kubectl get pods -n tekton-pipelines
```
