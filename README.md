# raelix-cluster-v2

## Installation guide

### Deploy the secret containing the private-key
You must have the age.agekey used previously to encrypt the contained secrets

```shell
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```
> N.B.: the flux-system may not be already present in that case create it with ```kubectl create ns flux-system```

### Restore the cluster
In order to restore the cluster you just need to apply the main flux resource. The main folder is ```cluster/production/flux-system```. You can use kustomize to render the manifest and apply them on the cluster.

## Developer guide
This developer guide is useful just to remember the important steps.
### Secret encryption
Generate the age pub and private key
```shell
age-keygen -o age.agekey
```

#### Create the secret
Create the secret that will be use by the kustomize controller

```shell
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```

#### Add the decryption section to the kustomize controller
```
add the decryption section to the kustomize controller

  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

#### Encryption rules
The encryption rule is defined in the root directory of the project in a file called ```.sops.yaml``` which contains the rules and the age public key to use for the encryption:
```
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    age: age1elje5gj3cyqhn44m66xlngczm8dklwmry9803ne69945e256xgequ9xtt6
```
#### Encrypt a secret
To encrypt a secret just run the ```encrypt_me.sh``` passing as first argument the secret yaml file. The script just runs the ```sops -e $1 | tee $1.encrypted``` command which uses the previous defined rule.

### Apps details
This section contains the main part related to the application deployment

#### EMQX
EMQX is deployed through the operator hence a new CR must be created in order to spawn the cluster. Unfortunately the dashboard user and the mqtt user can't be created easly hence a sidecar is used to do that using the REST API

##### Users secret
The expected secret to create the users is something like:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mqtt-users
  namespace: default
data:
  users.json: BASE64ENCODED_BELOW_JSON
```

This can be generated with the kubectl command:
```shell
kubectl create secret generic secret-name --from-file=./user.json --dry-run=client -o yaml
```

Where the user.json is like:
```json
// this is just an example 
{
  "user_id": "user",
  "password": "password",
  "is_superuser": true
}
```
The secret is then encrypted using the ```encrypt_me.sh``` script.

##### Dashboard secret
The expected secret to create define the dashboard user and password is something like:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-auth
type: Opaque
data:
  EMQX_DASHBOARD__DEFAULT_USERNAME: BASE64ENCODED_USERNAME
  EMQX_DASHBOARD__DEFAULT_PASSWORD: BASE64ENCODED_PASSWORD
```
The secret is then encrypted using the ```encrypt_me.sh``` script.