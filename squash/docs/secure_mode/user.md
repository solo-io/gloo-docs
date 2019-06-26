---
title: Using Secure Mode
weight: 2
---

## Using Secure Mode

### Per-cluster configuration

- Once per cluster, you need to register the squash resource, the `debugattachment` Custom Resource Definition (CRD). This can be done with `squashctl`. Note, you must have registration permissions to perform this operation.

```bash
squashctl utils register-resources
```

### Per-user configuration

- When Squash has been deployed in your cluster (see [Secure Mode Admin documentation](../admin)), you just need to update your `~/.squash/config.yaml` as follows:

```yaml
# Squash config file
secure_mode: true
```

- After you have set this value, you can use Squash in the same way as in the default mode.

