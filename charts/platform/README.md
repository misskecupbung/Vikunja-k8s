# Platform Helm Chart

Provides a shared GCE ingress for the Vikunja and Keycloak services with a single global static IP.

## Values

| Key | Description | Default |
|-----|-------------|---------|
| `staticIpName` | Name of existing Global Static IP (created outside) | `todo-platform-lb-ip` |
| `ingressClass` | Ingress class to use | `gce` |
| `hosts.vikunja` | Hostname for Vikunja frontend/API | `vikunja.local` |
| `hosts.keycloak` | Hostname for Keycloak | `keycloak.local` |

## Install

```
helm upgrade --install platform ./charts/platform \
  --set staticIpName=todo-platform-lb-ip \
  --set hosts.vikunja=vikunja.example.com \
  --set hosts.keycloak=auth.example.com
```

## Notes
- Additional custom annotations can be added by extending the template (loop removed initially to satisfy strict YAML linter in CI). Add under `metadata.annotations` as needed.
- Both backend Services (vikunja, keycloak) must expose port 80 and have NEG annotations for container-native load balancing.
