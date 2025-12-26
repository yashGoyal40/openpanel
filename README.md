# OpenPanel Helm Chart

A Helm chart for deploying OpenPanel analytics platform on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to access your cluster

## Installation

### Step 1: Add the Helm Repository

```bash
helm repo add openpanel https://yashGoyal40.github.io/openpanel
helm repo update
```

### Step 2: Configure Required Values

**⚠️ IMPORTANT:** Before installing, you **MUST** configure the required values in `values.yaml`. The chart includes placeholder values (marked with `<>`) that will cause the installation to fail if not properly configured.

Create a custom values file or download the default values:

```bash
helm show values openpanel/openpanel > my-values.yaml
```

Then edit `my-values.yaml` with your configuration (see [Required Configuration](#required-configuration) below).

### Step 3: Install OpenPanel

```bash
helm install my-openpanel openpanel/openpanel --version 1.0.0 --namespace openpanel --create-namespace -f my-values.yaml
```

Or if you want to override specific values directly:

```bash
helm install my-openpanel openpanel/openpanel --version 1.0.0 --namespace openpanel --create-namespace \
  --set ingress.fqdn=your-domain.com \
  --set config.apiUrl=https://your-domain.com/api \
  --set secrets.cookieSecret=$(openssl rand -base64 32)
```

## Quick Start Example

Here's a minimal example configuration file (`my-values.yaml`) with all required values:

```yaml
# Ingress Configuration
ingress:
  enabled: true
  type: standard  # or "httpproxy" for Contour
  fqdn: analytics.example.com
  standard:
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"  # For Let's Encrypt
    # tlsSecretName: openpanel-tls  # Optional: Only needed for manual TLS certs

# Application URLs
config:
  apiUrl: "https://analytics.example.com/api"
  dashboardUrl: "https://analytics.example.com"
  googleRedirectUri: "https://analytics.example.com/api/oauth/google/callback"

# Cookie Secret (generate with: openssl rand -base64 32)
secrets:
  cookieSecret: "YOUR_GENERATED_SECRET_HERE"

# PostgreSQL - Using External Database
postgresql:
  enabled: false

externalPostgresql:
  host: "postgres.example.com"
  port: 5432
  user: "openpanel"
  password: "your-secure-password"
  database: "openpanel"
  schema: public
```

Then install with:

```bash
helm install my-openpanel openpanel/openpanel --namespace openpanel --create-namespace -f my-values.yaml
```

## Required Configuration

The following values **MUST** be configured before installation. These are marked with `<>` placeholders in the default `values.yaml` and will prevent the chart from working correctly if left unchanged.

### 1. Ingress Configuration (Required)

Configure your fully qualified domain name (FQDN) and TLS settings:

```yaml
ingress:
  enabled: true
  type: httpproxy  # or "standard" for nginx/traefik
  fqdn: your-domain.com  # Replace <fqdn> with your actual domain
  
  # For HTTPProxy (Contour)
  httpproxy:
    tlsSecretName: openpanel-tls  # Optional: Only needed for manual TLS certs
  
  # For standard Ingress
  standard:
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"  # For Let's Encrypt via cert-manager
    # tlsSecretName: openpanel-tls  # Optional: Leave empty/unset when using cert-manager/Let's Encrypt
```

**TLS Configuration Options:**

1. **Using cert-manager/Let's Encrypt (Recommended):**
   - Leave `tlsSecretName` empty or unset
   - Add the `cert-manager.io/cluster-issuer` annotation (as shown above)
   - cert-manager will automatically create and manage the TLS certificate

2. **Using Manual TLS Certificate:**
   - Set `tlsSecretName` to your existing Kubernetes secret name
   - Ensure the secret exists in the same namespace before installation

**Examples:**
- `fqdn: analytics.example.com`
- For cert-manager: Leave `tlsSecretName` unset (or commented out)
- For manual certs: `tlsSecretName: openpanel-tls`

### 2. Application URLs (Required)

Configure the API and Dashboard URLs to match your ingress FQDN:

```yaml
config:
  apiUrl: "https://your-domain.com/api"  # Replace <fqdn> with your domain
  dashboardUrl: "https://your-domain.com"  # Replace <fqdn> with your domain
  googleRedirectUri: "https://your-domain.com/api/oauth/google/callback"  # Replace <fqdn>
```

**Example:**
```yaml
config:
  apiUrl: "https://analytics.example.com/api"
  dashboardUrl: "https://analytics.example.com"
  googleRedirectUri: "https://analytics.example.com/api/oauth/google/callback"
```

### 3. Cookie Secret (Required)

Generate a secure random string for session management:

```bash
openssl rand -base64 32
```

Then set it in `values.yaml`:

```yaml
secrets:
  cookieSecret: "YOUR_GENERATED_SECRET_HERE"  # Replace CHANGE_ME_GENERATE_A_RANDOM_32_CHAR_STRING
```

**⚠️ Security Note:** Never use the default value in production!

### 4. PostgreSQL Configuration (Required - Choose One)

#### Option A: External PostgreSQL (Recommended for Production)

If you have an existing PostgreSQL database:

```yaml
postgresql:
  enabled: false

externalPostgresql:
  host: "postgres.example.com"  # Replace <postgres_host>
  port: 5432
  user: "openpanel"  # Replace <postgres_user>
  password: "your-secure-password"  # Replace <postgres_password>
  database: "openpanel"  # Replace <database_name>
  schema: public
```

#### Option B: Self-Hosted PostgreSQL

To deploy PostgreSQL within Kubernetes:

```yaml
postgresql:
  enabled: true
  user: postgres
  password: "your-secure-password"  # Change from default!
  database: postgres
  persistence:
    size: 20Gi
```

**⚠️ Note:** If using self-hosted PostgreSQL, you don't need to configure `externalPostgresql` section.

### 5. Optional: Email Configuration

If you want to enable email functionality (password resets, invitations, etc.):

```yaml
secrets:
  resendApiKey: "re_xxxxxxxxxxxxx"  # Replace <resend_api_key> with your Resend API key
  emailSender: "noreply@your-domain.com"  # Replace <email_sender> with your verified sender email
```

**Getting a Resend API Key:**
1. Sign up at [resend.com](https://resend.com)
2. Create an API key in the dashboard
3. Verify your sender email domain
4. Add the API key and sender email to your values

### 6. Optional: AI Features

If you want to enable AI-powered features:

```yaml
config:
  aiModel: "gpt-4o-mini"  # Options: gpt-4o, gpt-4o-mini, claude-3-5

secrets:
  openaiApiKey: "sk-xxxxxxxxxxxxx"  # Replace <openai_api_key> for OpenAI models
  anthropicApiKey: ""  # Leave empty if not using Anthropic/Claude models
  geminiApiKey: ""  # Leave empty if not using Gemini models
```

**Important Notes:**
- You only need to configure the API key for the model you choose:
  - For `gpt-4o` or `gpt-4o-mini`: Configure `openaiApiKey`
  - For `claude-3-5`: Configure `anthropicApiKey`
- **You can leave `anthropicApiKey` and `geminiApiKey` empty** (as empty strings `""`) if you don't want to use those features
- Only configure the API keys for the AI providers you plan to use

### 7. Optional: Google OAuth

If you want to enable Google OAuth login:

```yaml
secrets:
  googleClientId: "xxxxx.apps.googleusercontent.com"  # Replace <google_client_id>
  googleClientSecret: "GOCSPX-xxxxxxxxxxxxx"  # Replace <google_client_secret>
```

**Setting up Google OAuth:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new OAuth 2.0 Client ID
3. Add authorized redirect URI: `https://your-domain.com/api/oauth/google/callback`
4. Copy the Client ID and Client Secret to your values

## Configuration Summary

| Configuration | Required | Placeholder | Description |
|--------------|----------|-------------|-------------|
| `ingress.fqdn` | ✅ Yes | `<fqdn>` | Your domain name |
| `ingress.*.tlsSecretName` | ⚠️ Conditional | `<tls_secret_name>` | TLS certificate secret name (optional when using cert-manager/Let's Encrypt) |
| `config.apiUrl` | ✅ Yes | `<fqdn>` | Full API URL |
| `config.dashboardUrl` | ✅ Yes | `<fqdn>` | Full Dashboard URL |
| `config.googleRedirectUri` | ✅ Yes | `<fqdn>` | OAuth callback URL |
| `secrets.cookieSecret` | ✅ Yes | `CHANGE_ME_...` | Session encryption key |
| `externalPostgresql.host` | ⚠️ If external | `<postgres_host>` | PostgreSQL hostname |
| `externalPostgresql.user` | ⚠️ If external | `<postgres_user>` | PostgreSQL username |
| `externalPostgresql.password` | ⚠️ If external | `<postgres_password>` | PostgreSQL password |
| `externalPostgresql.database` | ⚠️ If external | `<database_name>` | PostgreSQL database name |
| `secrets.resendApiKey` | ❌ Optional | `<resend_api_key>` | Resend API key for emails (leave empty `""` if not using) |
| `secrets.emailSender` | ❌ Optional | `<email_sender>` | Verified sender email (leave empty `""` if not using) |
| `secrets.openaiApiKey` | ❌ Optional | `<openai_api_key>` | OpenAI API key (leave empty `""` if not using OpenAI) |
| `secrets.anthropicApiKey` | ❌ Optional | `<anthropic_api_key>` | Anthropic API key (leave empty `""` if not using Anthropic/Claude) |
| `secrets.geminiApiKey` | ❌ Optional | `<gemini_api_key>` | Gemini API key (leave empty `""` if not using Gemini) |
| `secrets.googleClientId` | ❌ Optional | `<google_client_id>` | Google OAuth Client ID (leave empty `""` if not using) |
| `secrets.googleClientSecret` | ❌ Optional | `<google_client_secret>` | Google OAuth Client Secret (leave empty `""` if not using) |

## Additional Configuration

### Redis Configuration

Redis is enabled by default and will be deployed within Kubernetes. To use an external Redis instance:

```yaml
redis:
  enabled: false

externalRedis:
  host: "redis.example.com"  # Replace with your Redis host
  port: 6379
```

### ClickHouse Configuration

ClickHouse is enabled by default and will be deployed within Kubernetes. To use an external ClickHouse instance:

```yaml
clickhouse:
  enabled: false

externalClickhouse:
  host: "clickhouse.example.com"  # Replace with your ClickHouse host
  port: 8123
  database: openpanel
```

### Application Components

You can enable/disable individual components:

```yaml
api:
  enabled: true
  replicas: 1

dashboard:
  enabled: true
  replicas: 1

worker:
  enabled: true
  replicas: 1
```

### Resource Limits

Adjust resource requests and limits based on your cluster capacity:

```yaml
api:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "2Gi"
      cpu: "2000m"
```

### Horizontal Pod Autoscaler (HPA)

Enable automatic scaling of pods based on CPU and memory utilization. HPA can be configured for the API, Dashboard, and Worker components.

**Prerequisites:**
- Kubernetes Metrics Server must be installed in your cluster
- Resource requests must be set for the pods (see [Resource Limits](#resource-limits) above)

**Basic HPA Configuration:**

```yaml
api:
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

dashboard:
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

worker:
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

**HPA Configuration Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Enable/disable HPA for the component | `false` |
| `minReplicas` | Minimum number of pods | `1` |
| `maxReplicas` | Maximum number of pods | `10` |
| `targetCPUUtilizationPercentage` | Target CPU utilization percentage (optional) | `70` |
| `targetMemoryUtilizationPercentage` | Target memory utilization percentage (optional) | `80` |

**Important Notes:**
- HPA requires resource requests to be set on pods. Make sure you've configured `resources.requests` for the component.
- If both CPU and memory targets are set, HPA will scale when either threshold is exceeded.
- For production environments, consider setting `minReplicas` to 2 or higher for high availability.

### Taints and Tolerations

If your Kubernetes cluster has tainted nodes, you can configure tolerations for each component to allow pods to be scheduled on those nodes:

```yaml
# Example: Allow API pods to run on nodes with a dedicated taint
api:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "api"
      effect: "NoSchedule"

# Example: Allow PostgreSQL pods to run on database-dedicated nodes
postgresql:
  tolerations:
    - key: "database"
      operator: "Equal"
      value: "postgresql"
      effect: "NoSchedule"

# Example: Multiple tolerations for ClickHouse
clickhouse:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "analytics"
      effect: "NoSchedule"
    - key: "workload"
      operator: "Equal"
      value: "heavy"
      effect: "NoExecute"
```

**Available components:**
- `api.tolerations` - Tolerations for API pods
- `dashboard.tolerations` - Tolerations for Dashboard pods
- `worker.tolerations` - Tolerations for Worker pods
- `postgresql.tolerations` - Tolerations for PostgreSQL pods
- `redis.tolerations` - Tolerations for Redis pods
- `clickhouse.tolerations` - Tolerations for ClickHouse pods

**Toleration effects:**
- `NoSchedule` - Pods will not be scheduled on tainted nodes unless they have a matching toleration
- `PreferNoSchedule` - Kubernetes will try to avoid scheduling pods on tainted nodes, but it's not required
- `NoExecute` - Pods already running on the node will be evicted if they don't have a matching toleration

### Pod Affinity and Anti-Affinity

You can configure pod affinity and anti-affinity rules to control pod scheduling based on node labels or other pods:

```yaml
# Example: Schedule API pods only on nodes with specific label
api:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: app
            operator: In
            values:
            - openpanel

# Example: Schedule PostgreSQL pods with node affinity
postgresql:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: app
            operator: In
            values:
            - openpanel

# Example: Pod anti-affinity to spread pods across nodes
api:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - openpanel-api
          topologyKey: kubernetes.io/hostname
```

**Available components:**
- `api.affinity` - Affinity rules for API pods
- `dashboard.affinity` - Affinity rules for Dashboard pods
- `worker.affinity` - Affinity rules for Worker pods
- `postgresql.affinity` - Affinity rules for PostgreSQL pods
- `redis.affinity` - Affinity rules for Redis pods
- `clickhouse.affinity` - Affinity rules for ClickHouse pods

**Affinity types:**
- `nodeAffinity` - Control which nodes pods can be scheduled on based on node labels
- `podAffinity` - Schedule pods together with other pods matching certain labels
- `podAntiAffinity` - Avoid scheduling pods together with other pods matching certain labels

## Upgrading

### Upgrading to a newer version

To upgrade to a newer version:

```bash
helm repo update
helm upgrade my-openpanel openpanel/openpanel --version <new-version> --namespace openpanel -f my-values.yaml
```

Replace `<new-version>` with the desired version number (e.g., `1.0.1`).

## Uninstallation

To uninstall OpenPanel:

```bash
helm uninstall my-openpanel --namespace openpanel
```

**⚠️ Warning:** This will delete all resources including persistent volumes. Make sure to backup your data before uninstalling.

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n openpanel
```

### View Logs
```bash
# API logs
kubectl logs -f deployment/op-api -n openpanel

# Dashboard logs
kubectl logs -f deployment/op-dashboard -n openpanel

# Worker logs
kubectl logs -f deployment/op-worker -n openpanel
```

### Check Services
```bash
kubectl get svc -n openpanel
```

### Check ConfigMap and Secrets
```bash
kubectl get configmap openpanel-config -n openpanel -o yaml
kubectl get secret openpanel-secrets -n openpanel -o yaml
```

## Values Reference

See `values.yaml` for all available configuration options with detailed comments.

## Support

For issues and questions, please refer to the OpenPanel documentation or create an issue in the repository.
https://github.com/yashGoyal40/openpanel
