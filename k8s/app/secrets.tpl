apiVersion: v1
kind: Secret
metadata:
  name: regcred
  annotations:
    kubernetes.io/service-account.name: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${BASE64_REGISTRY_CONFIG}
