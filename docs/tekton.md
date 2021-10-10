# Tekton

```sh
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl get namespace tekton-pipelines
# you can wait to see it RUNNING
watch kubectl get pods -n tekton-pipelines
```
