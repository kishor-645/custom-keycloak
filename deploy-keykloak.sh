#!/bin/bash
set -euo pipefail

# === Input Validation ===
if [ -z "$1" ]; then
  echo "❌ Usage: $0 <namespace> (e.g., dev, qa, prod, klk)"
  exit 1
fi

# === Minimal Variables ===
NAMESPACE="$1"
RELEASE_NAME="keycloak"
CHART_PATH="./keycloak-helm"
REALM_FILE="realm-import/realm-retc.json"

# === Keycloak & Database Credentials ===
KC_ADMIN_USER="admin"
KC_ADMIN_PASSWORD="E1SqKDb170AB"
DB_USER="keycloak_user"
DB_PASSWORD="DbSecretPass123"

# === Ensure Namespace exists ===
echo "🛠️ Ensuring namespace exists: ${NAMESPACE}"
if ! kubectl get ns "${NAMESPACE}" >/dev/null 2>&1; then
  echo "Creating namespace ${NAMESPACE}..."
  kubectl create ns "${NAMESPACE}"
else
  echo "Namespace ${NAMESPACE} already exists."
fi

# === Basic Checks ===
if [ ! -d "$CHART_PATH" ]; then
  echo "❌ Chart path not found: $CHART_PATH"
  exit 1
fi

if [ ! -f "$REALM_FILE" ]; then
  echo "❌ Realm file not found: $REALM_FILE"
  exit 1
fi

# === Helm Install/Upgrade ===
echo "🚀 Installing/Upgrading Keycloak: $RELEASE_NAME in namespace $NAMESPACE"
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set realmImport.enabled=true \
  --set replicaCount=1 \
  --set db.storageClass="longhorn" \
  --set auth.adminUser="$KC_ADMIN_USER" \
  --set auth.adminPassword="$KC_ADMIN_PASSWORD" \
  --set db.user="$DB_USER" \
  --set auth.dbPassword="$DB_PASSWORD" \
  --set-file realmImport.content="$REALM_FILE" \
  --set service.type=LoadBalancer \
  --set service.port=8080

# === Wait for rollout ===
echo "⏳ Waiting for Keycloak pods to become ready (max 5 min)..."
if kubectl wait --for=condition=Ready pod -l "app=keycloak" \
  --namespace "${NAMESPACE}" --timeout=300s 2>/dev/null; then
  echo "✅ Keycloak pods are READY"
  kubectl get pods -n "${NAMESPACE}"
else
  echo "⚠️ Warning: Pods may still be initializing. Checking status..."
  kubectl get pods -n "${NAMESPACE}"
fi

echo ""
echo "✅ Keycloak deployed in namespace '$NAMESPACE'"
echo "🔗 Access → kubectl port-forward -n $NAMESPACE svc/keycloak 8080:8080"
echo "   Then visit → http://localhost:8080"
echo ""
