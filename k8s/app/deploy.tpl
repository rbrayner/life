apiVersion: apps/v1
kind: Deployment
metadata:
  name: life
spec:
  replicas: 3
  selector:
    matchLabels:
      app: life
  template:
    metadata:
      labels:
        app: life
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: app
          image: ${IMAGE_NAME}:${IMAGE_VERSION}
          ports:
            - containerPort: 3000
          readinessProbe:
            httpGet:
              path: /posts
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /posts
              port: 3000
            initialDelaySeconds: 60
            periodSeconds: 10