---
title: JWT and Access Control
weight: 2
description: JWT verification and Access Control (without an external auth server)
---

## Pre-requesites

We will use the following utilities

- minikube
- jq
- gloo enterprise version v0.13.16 or later.

## Initial setup

Start minikube:
```
minikube start
```

Install gloo-enterprise and create a virtual service and an example app:
```shell
glooctl install gateway --license-key <YOUR KEY>
```

Wait for the deployment to finish:
```shell
kubectl -n gloo-system rollout status deployment/discovery
kubectl -n gloo-system rollout status deployment/gateway
kubectl -n gloo-system rollout status deployment/gloo
kubectl -n gloo-system rollout status deployment/gateway-proxy
```

Install the petstore demo app and add a route and test that everything so far works (you may need to wait a minutes until all the gloo containers are initialized):
```shell
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
glooctl add route --name default --namespace gloo-system --path-prefix / --dest-name default-petstore-8080 --dest-namespace gloo-system
URL=$(glooctl proxy url)
```

Test that everything so far works:
```
curl $URL/api/pets/
[{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
```

## Setting up JWT authorization

Let's create a test pod, with a different service account. We will use this pod in the guide to test
access with the new service account credentials.

```shell
kubectl create serviceaccount svc-a
kubectl run --generator=run-pod/v1 test-pod --image=fedora:30 --serviceaccount=svc-a --command sleep 10h
```

### Anatomy of kuberentes service account

When kuberentes starts a pod, it automatically attaches to it a JWT (JSON Web Token), that allows 
for authentication with the credentials of the pod's service account.
Inside the JWT are *claims* that provide idtentity information, and a signature to verification.

To verify these JWT, the kubernetes api server is provided with a public key. We can use this public 
key to perform JWT verification for kubernetes service accounts in Gloo.

Let's see the claims for `svc-a` - the service account we just created:

```shell
CLAIMS=$(kubectl exec test-pod cat /var/run/secrets/kubernetes.io/serviceaccount/token | cut -d. -f2)
PADDING=$(head -c $((${#CLAIMS} % 3)) /dev/zero |tr '\0' =)
PADDED_CLAIMS="${CLAIMS}${PADDING}"
echo $PADDED_CLAIMS | base64 --decode |jq .
```
The output should look like so:
```json
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "default",
  "kubernetes.io/serviceaccount/secret.name": "svc-a-token-tssts",
  "kubernetes.io/serviceaccount/service-account.name": "svc-a",
  "kubernetes.io/serviceaccount/service-account.uid": "279d1e33-8d59-11e9-8f04-80c697af5b67",
  "sub": "system:serviceaccount:default:svc-a"
}
```

{{% notice note %}}
In your output the `kubernetes.io/serviceaccount/service-account.uid` claim will be different than displayed here.
{{% /notice %}}

The most important claims for this guide are the *iss* claim and the *sub* claim. We will use these
claims later to verify the identity of the JWT.

### Configuring Gloo to verify service account JWT

To get the public key for verify service accounts, use this command:
```shell
minikube ssh sudo cat /var/lib/minikube/certs/sa.pub | tee public-key.pem
```
This command will output the public key, and will save it to a file called `public-key.pem`.
```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4XbzUpqbgKbDLngsLp4b
pjf04WkMzXx8QsZAorkuGprIc2BYVwAmWD2tZvez4769QfXsohu85NRviYsrqbyC
w/NTs3fMlcgld+ayfb/1X3+6u4f1Q8JsDm4fkSWoBUlTkWO7Mcts2hF8OJ8LlGSw
zUDj3TJLQXwtfM0Ty1VzGJQMJELeBuOYHl/jaTdGogI8zbhDZ986CaIfO+q/UM5u
kDA3NJ7oBQEH78N6BTsFpjDUKeTae883CCsRDbsytWgfKT8oA7C4BFkvRqVMSek7
FYkg7AesknSyCIVMObSaf6ZO3T2jVGrWc0iKfrR3Oo7WpiMH84SdBYXPaS1VdLC1
7QIDAQAB
-----END PUBLIC KEY-----
```


{{% notice note %}}
If the above command doesn't produce the expected output, it could be that the
`/var/lib/minikube/certs/sa.pub` is different on your minikube.
The public key is given to the kube api-server in the command line arg `--service-account-key-file`.
You can see it like so: `minikube ssh ps ax ww |grep kube-apiserver`
{{% /notice %}}

Configure JWT verification in Gloo's default virtual service:

```shell
# escape the spaces in the public key file:
PUBKEY=$(cat public-key.pem|python -c 'import json,sys; print(json.dumps(sys.stdin.read()).replace(" ", "\\u0020"))')
# patch the default virtual service
kubectl patch virtualservice --namespace gloo-system default --type=merge -p '{"spec":{"virtualHost":{"virtualHostPlugins":{"extensions":{"configs":{"jwt":{"jwks":{"local":{"key":'$PUBKEY'}},"issuer":"kubernetes/serviceaccount"}}}}}}}' -o yaml
```
The output should look like so:
```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.default
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
    virtualHostPlugins:
      extensions:
        configs:
          jwt:
            issuer: kubernetes/serviceaccount
            jwks:
              local:
                key: "-----BEGIN PUBLIC KEY-----\r\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4XbzUpqbgKbDLngsLp4b\r\npjf04WkMzXx8QsZAorkuGprIc2BYVwAmWD2tZvez4769QfXsohu85NRviYsrqbyC\r\nw/NTs3fMlcgld+ayfb/1X3+6u4f1Q8JsDm4fkSWoBUlTkWO7Mcts2hF8OJ8LlGSw\r\nzUDj3TJLQXwtfM0Ty1VzGJQMJELeBuOYHl/jaTdGogI8zbhDZ986CaIfO+q/UM5u\r\nkDA3NJ7oBQEH78N6BTsFpjDUKeTae883CCsRDbsytWgfKT8oA7C4BFkvRqVMSek7\r\nFYkg7AesknSyCIVMObSaf6ZO3T2jVGrWc0iKfrR3Oo7WpiMH84SdBYXPaS1VdLC1\r\n7QIDAQAB\r\n-----END
                  PUBLIC KEY-----\r\n"
```

The update virtual service now contains JWT configuration with the public key, and the issuer for the JWT.

## Configuring Gloo to perform access control for the service account

To make this interesting, we can add access control policy for JWT. let's add a policy to the virtual service:
```shell
POLICIES='{
"policies": {
    "viewer": {
        "principals":[{
            "jwtPrincipal":{"claims":{"sub":"system:serviceaccount:default:svc-a"}}
        }],
        "permissions":{
            "pathPrefix":"/api/pets",
            "methods":["GET"]
        }
    }
}
}'
# remove spaces
POLICIES=$(echo $POLICIES|jq -c .)
kubectl patch virtualservice --namespace gloo-system default --type=merge -p '{"spec":{"virtualHost":{"virtualHostPlugins":{"extensions":{"configs":{"rbac":{"config":'$POLICIES'}}}}}}}' -o yaml
```

The output should look like so:
```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.default
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
    virtualHostPlugins:
      extensions:
        configs:
          jwt:
            issuer: kubernetes/serviceaccount
            jwks:
              local:
                key: "-----BEGIN PUBLIC KEY-----\r\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4XbzUpqbgKbDLngsLp4b\r\npjf04WkMzXx8QsZAorkuGprIc2BYVwAmWD2tZvez4769QfXsohu85NRviYsrqbyC\r\nw/NTs3fMlcgld+ayfb/1X3+6u4f1Q8JsDm4fkSWoBUlTkWO7Mcts2hF8OJ8LlGSw\r\nzUDj3TJLQXwtfM0Ty1VzGJQMJELeBuOYHl/jaTdGogI8zbhDZ986CaIfO+q/UM5u\r\nkDA3NJ7oBQEH78N6BTsFpjDUKeTae883CCsRDbsytWgfKT8oA7C4BFkvRqVMSek7\r\nFYkg7AesknSyCIVMObSaf6ZO3T2jVGrWc0iKfrR3Oo7WpiMH84SdBYXPaS1VdLC1\r\n7QIDAQAB\r\n-----END
                  PUBLIC KEY-----\r\n"
          rbac:
            config:
              policies:
                viewer:
                  permissions:
                    methods:
                    - GET
                    pathPrefix: /api/pets
                  principals:
                  - jwtPrincipal:
                      claims:
                        sub: system:serviceaccount:default:svc-a
```

### Test

Let's verify that everything is working properly:

An un-authenticated request should fail (will output *Jwt is missing*):
```shell
kubectl exec test-pod --  bash -c 'curl -s http://gateway-proxy.gloo-system/api/pets/1'
```

An authenticated GET request to that start with /api/pets should succeed:
```shell
kubectl exec test-pod --  bash -c 'curl -s http://gateway-proxy.gloo-system/api/pets/1 -H"Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'
```

An authenticated POST request to that start with /api/pets should fail (will output *RBAC: access denied*):
```shell
kubectl exec test-pod --  bash -c 'curl -s -XPOST http://gateway-proxy.gloo-system/api/pets/1 -H"Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'
```

An authenticated GET request to that doesn't start with /api/pets should fail (will output *RBAC: access denied*):
```shell
kubectl exec test-pod --  bash -c 'curl -s http://gateway-proxy.gloo-system/foo/ -H"Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'
```

## Conclusion

We have used Gloo to verify service account identity, and provide access control. In this guide we demonstrated using gloo as an internal API gateway, and performing access control using kubernetes service accounts.

## Cleanup

To clean up:
```shell
kubectl delete pod test-pod
kubectl delete -f https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
glooctl uninstall
rm public-key.pem
minikube delete
```
