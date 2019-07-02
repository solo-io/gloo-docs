# Gloo docs

## Deploying to a test site

A dockerfile and nginx configuration are included in this directory. To package up the docs, run: 

```
make site -B
docker build -t CONTAINER_REPO/gloo-docs:dev .
docker push CONTAINER_REPO/gloo-docs:dev
```
