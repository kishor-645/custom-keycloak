#!/bin/bash

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
  --set-file realmImport.content="$REALM_FILE" \
  --set service.type=LoadBalancer \
  --set service.port=8080

echo "✅ Keycloak deployed in namespace '$NAMESPACE'"
