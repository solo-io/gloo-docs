# DEPRECATED

Gloo's docs are now stored in the gloo repo. Docs in this directory will no longer be hosted at gloo.solo.io.

This folder will still be used by legacy branches of Gloo to collect the docs generated from the corresponding API and CLI.

When Gloo v0.20.x is deprecated this directory can be removed.

Please visit docs.solo.io/gloo/latest/ for the latest version of the Gloo documentation.





# Gloo docs

## Deploying to a test site

A dockerfile and nginx configuration are included in this directory. To package up the docs, run: 

```
make site -B
docker build -t CONTAINER_REPO/gloo-docs:dev .
docker push CONTAINER_REPO/gloo-docs:dev
```
