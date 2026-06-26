#!/usr/bin/env bash

PORT=8000
HOST_PORT=8001
API_PORT=8002

DATA_DIR=${PERSONFINDER_DIR}data
mkdir -p ${DATA_DIR}

cd ${PERSONFINDER_DIR}

echo "Compiling translation files..."
find app/locale -name "django.po" | while read po; do
    msgfmt -o "${po%.po}.mo" "$po"
done
echo "Translation files compiled."

echo "Starting Person Finder server"
dev_appserver.py app \
  --host 0.0.0.0 \
  --port ${PORT} \
  --admin_host=0.0.0.0 \
  --admin_port=${HOST_PORT} \
  --api_host=0.0.0.0 \
  --api_port=${API_PORT} \
  --datastore_path=${DATA_DIR}/datastore.db \
  --blobstore_path=${DATA_DIR}/blobstore \
  --support_datastore_emulator=False \
  --enable_host_checking=false \
  --skip_sdk_update_check
echo "Person Finder server stopped"
