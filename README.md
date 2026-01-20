# Keycloak Production-Grade Helm Chart

This Helm chart deploys a fully independent, production-ready **Keycloak 26** cluster on Kubernetes. It is built to be vendor-neutral, highly available, and secure.

## 🚀 Features

*   **Keycloak 26 (Quarkus):** Optimized for the latest version of Keycloak.
*   **High Availability:** Ready for multi-replica deployment with Infinispan clustering (DNS discovery).
*   **Persistence:** Uses **StatefulSets** and **Persistent Volume Claims (PVC)** for both Keycloak and PostgreSQL.
*   **Secure:** Sensitive credentials (passwords) are managed via Kubernetes Secrets.
*   **Management Port:** Health checks are isolated on port `9000` (Security Best Practice).
*   **Realm Import:** Built-in capability to automatically import a `jhipster-realm.json` or any other realm file on startup.
*   **Conditional Ingress:** Easy toggle for Ingress and TLS configuration.

---

## 🛠 Configuration Parameters

| Parameter | Description | Default |
| :--- | :--- | :--- |
| `replicaCount` | Number of Keycloak nodes (use `2+` for HA) | `2` |
| `auth.adminUser` | Initial Admin Username | `admin` |
| `auth.adminPassword` | Initial Admin Password | `admin_password` |
| `db.storageClass` | Storage class for Postgres Persistence | `standard` |
| `db.storageSize` | Disk size for Database | `10Gi` |
| `resources.limits.memory` | Maximum RAM allowed for Keycloak pod | `2048Mi` |
| `ingress.enabled` | Toggle to create Ingress rules | `false` |
| `realmImport.enabled` | Toggle to import a JSON realm file | `false` |

---

## 📦 Installation Guide

### 1. Basic Installation (For Local/Dev)
Use this for a quick setup in a **Kind** or **Minikube** cluster.
```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace dev \
  --create-namespace
```

### 2. Production Installation (High Availability & Custom DB)
Use this for a real environment. We increase replicas and specify a cloud-based storage class.
```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace auth \
  --create-namespace \
  --set replicaCount=3 \
  --set db.storageClass="gp2" \
  --set auth.adminPassword="SecureAdminPassword123" \
  --set auth.dbPassword="SecureDbPassword123"
```

### 3. Installation with Ingress & TLS (Production HTTPS)
Enables external access via a domain name with SSL.
```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace auth \
  --set ingress.enabled=true \
  --set ingress.hostname="sso.example.com" \
  --set ingress.tls=true \
  --set ingress.className="nginx"
```

### 4. Installation with Realm Import (JHipster example)
If you have a `jhipster-realm.json` file, use the `--set-file` flag to inject it into the chart automatically.
```bash
helm upgrade --install keycloak ./keycloak-helm  --create-namespace \
  --namespace dev \
  --set realmImport.enabled=true \
  --set-file realmImport.content=jhipster-realm.json
```
```bash
helm upgrade --install keycloak ./keycloak-helm --namespace dev --set realmImport.enabled=true --set-file realmImport.content=realm-import/realm-retc.json.json
```

```bash
helm upgrade --install keycloak ./keycloak-helm --namespace dev --set realmImport.enabled=true --set-file realmImport.content=realm-import/realm-retc.json.json --set service.type=LoadBalancer
```

```bash
helm upgrade --install keycloak ./keycloak-helm --namespace dev --set realmImport.enabled=true --set-file realmImport.content=realm-import/realm-retc.json.json --set service.type=NodePort
```
---

## 🔍 Verification & Troubleshooting

### Check if pods are running
```bash
kubectl get pods -n dev
```

### Watch Keycloak startup logs
```bash
kubectl logs -f pod/keycloak-0 -n dev
```

### Access Keycloak locally (Port Forward)
If you are not using Ingress, you can access the UI by running:
```bash
kubectl port-forward svc/keycloak 8080:8080 -n dev
```
Then visit: **`http://localhost:8080`**

### Check if the Cluster is working (HA check)
Log into the Keycloak pod and check the logs for this line:
`Received new cluster view for channel ISPN: [my-keycloak-0|1] (2) [my-keycloak-0, my-keycloak-1]`
This confirms the pods have found each other and are sharing sessions.

---

## ⚠️ Important Notes
*   **Storage Class:** Ensure the `db.storageClass` matches a class available in your cluster (`kubectl get sc`).
*   **Admin Credentials:** Keycloak only creates the admin user on the **very first boot**. If you change the password in `values.yaml` later, it will not change the password of an existing database.
*   **Resources:** Keycloak 26 (Quarkus) requires at least 1GB of RAM to start comfortably. Do not set limits lower than `1024Mi`.