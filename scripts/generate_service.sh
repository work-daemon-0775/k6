#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <project_name>  <service_name> <service_url>"
    exit 1
fi

PROJECT_NAME=$1
SERVICE_NAME=$2
SERVICE_URL=$3
OUTPUT_DIR="/ci/k6/${PROJECT_NAME}/${SERVICE_NAME}"
SCRIPT_PATH="${OUTPUT_DIR}/script.js"

echo "Generating OpenAPI client for service: $SERVICE_NAME"

mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}/data

# Генерируем клиент из OpenAPI
openapi-generator-cli generate \
  -i "https://${SERVICE_URL}/openapi.json" \
  -g k6 \
  -o "$OUTPUT_DIR" \
  --server-variables=host=https://prod.example.com/api

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate OpenAPI client"
    exit 1
fi

echo "Patching script.js..."

python3 /tmp/k6_envize.py ${SCRIPT_PATH}

sed -i "s|^[[:space:]]*const BASE_URL = \"/\";|const BASE_URL = \"https://${SERVICE_URL}\";|" "$SCRIPT_PATH"
