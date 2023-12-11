apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  password: ${DB_PASSWORD_BASE64}