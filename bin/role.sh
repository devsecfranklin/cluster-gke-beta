
ns="dev-$(whoami)"

kubectl create namespace ${ns}
kubectl annotate namespace ${ns} dev=franklin

cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ns}
  namespace: ${ns}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: user
  name: $(whoami)
EOF
