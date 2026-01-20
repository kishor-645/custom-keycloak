FROM quay.io/keycloak/keycloak:24.0.1

# Copy realm and user import files
COPY realm-import /opt/keycloak/data/import

# Expose Keycloak port
EXPOSE 8080

# Start Keycloak and import realm
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start-dev", "--import-realm"]