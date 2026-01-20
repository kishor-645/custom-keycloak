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
| `replicaCount` | Number of Keycloak nodes (use `2+` for HA) | `1` |
| `auth.adminUser` | Initial Admin Username | `admin` |
| `auth.adminPassword` | Initial Admin Password | `admin_password` |
| `db.replicas` | Number of Database replicas (StatefulSet) | `2` |
| `db.storageClass` | Storage class for Postgres Persistence | `standard` |
| `db.storageSize` | Disk size for Database | `10Gi` |
| `nodeSelector."kubernetes.io/hostname"` | Worker node hostname to deploy pods | `srvk8sworker1` |
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
helm upgrade --install keycloak ./keycloak-helm --namespace dev --set realmImport.enabled=true --set-file realmImport.content=realm-import/realm-retc.json
```

### 5. Installation with Custom Worker Node (Node Affinity)
Force Keycloak and Database pods to deploy on a specific worker node. This is useful for on-prem deployments where storage is node-local or when you want to isolate workloads.

**First, find your available nodes:**
```bash
kubectl get nodes --show-labels
```

Look for the `kubernetes.io/hostname` label. Example output:
```
srvk8sworker1   Ready    worker   45d   v1.27.0   kubernetes.io/hostname=srvk8sworker1
srvk8sworker2   Ready    worker   45d   v1.27.0   kubernetes.io/hostname=srvk8sworker2
```

**Then deploy to a specific worker:**
```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace dev \
  --create-namespace \
  --set "nodeSelector.kubernetes\.io/hostname=srvk8sworker1"
```

### 6. Installation with Custom Database Replicas
Control the number of database replicas for your Postgres StatefulSet.

```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace dev \
  --create-namespace \
  --set db.replicas=3
```

### 7. Combined Example: Custom Node + Custom DB Replicas + Realm Import
```bash
helm upgrade --install keycloak ./keycloak-helm \
  --namespace dev \
  --create-namespace \
  --set "nodeSelector.kubernetes\.io/hostname=srvk8sworker1" \
  --set db.replicas=3 \
  --set replicaCount=2 \
  --set realmImport.enabled=true \
  --set-file realmImport.content=realm-import/realm-retc.json \
  --set service.type=LoadBalancer
```
---

## 🔍 Verification & Troubleshooting

### Check if pods are running
```bash
kubectl get pods -n dev
```

### Check if pods are deployed to the correct worker node
When using `nodeSelector`, verify that both Keycloak and Database pods are running on the specified node:
```bash
kubectl get pods -o wide -n dev
```
Look at the **NODE** column. All pods should show the same worker node hostname (e.g., `srvk8sworker1`).

### Verify database replica count
```bash
kubectl get statefulsets -n dev
kubectl describe statefulset keycloak-db -n dev
```
Check the `Replicas` field to confirm it matches your configuration.

### Watch Keycloak startup logs
```bash
kubectl logs -f pod/keycloak-0 -n dev
```

### Access Keycloak locally (Port Forward)
If you are not using Ingress, you can access the UI by running:
```bash
kubectl port-forward svc/keycloak 8080:8080 -n dev
*   **Node Selector:** When using `nodeSelector`, ensure the specified worker node exists and is ready. Use `kubectl get nodes` to verify. If the node goes down, all pods will become unschedulable.
*   **Database Replicas on Single Node:** If you set `db.replicas=2` or higher with a single `nodeSelector`, all database replicas will run on the same worker node. This loses "Node High Availability" but gains stability for on-prem environments where storage is node-local.
*   **Finding Node Hostnames:** To get the exact hostname to use in `nodeSelector`, run:
    ```bash
    kubectl get nodes --show-labels | grep kubernetes.io/hostname
    ```
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