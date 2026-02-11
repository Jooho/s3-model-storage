#!/bin/bash
set -e
set -x
# Set variables
ENGINE=$1
FINAL_SEAWEEDFS_IMG=$2
BUCKET_NAME=$3
# PLATFORMS=${4:-"linux/amd64,linux/arm64"}
PLATFORMS=${4:-"linux/amd64"}
BASE_SEAWEEDFS_IMG="quay.io/jooholee/model-seaweedfs:copy"
INTRIM_SEAWEEDFS_IMG="quay.io/jooholee/model-seaweedfs:intrim"
CONTAINER_NAME="seaweedfs-setup-container"
SEAWEEDFS_ROOT_USER="admin"
SEAWEEDFS_ROOT_PASSWORD="admin"
echo ${FINAL_SEAWEEDFS_IMG}
echo ${BUCKET_NAME}

# Build SeaweedFS Images
$ENGINE build -t ${BASE_SEAWEEDFS_IMG} -f Dockerfile.copy .

# Run container in detached mode with root user to fix permissions
$ENGINE rm $CONTAINER_NAME --force
$ENGINE run --privileged --rm -d -v ./models:/tmp/models:rw --name $CONTAINER_NAME -e AWS_ACCESS_KEY_ID=$SEAWEEDFS_ROOT_USER -e AWS_SECRET_ACCESS_KEY=$SEAWEEDFS_ROOT_PASSWORD --user 1000:0 $BASE_SEAWEEDFS_IMG mini -dir=/data1 -s3

# Execute setup script inside the container
sleep 20 # Wait for SeaweedFS server to start
$ENGINE exec $CONTAINER_NAME /usr/bin/setup.sh $BUCKET_NAME

$ENGINE exec --user root $CONTAINER_NAME chmod 777 -R /data1
$ENGINE exec --user root $CONTAINER_NAME cp -R /data/. /data1/.
# Commit the container to create the interim image
$ENGINE commit $CONTAINER_NAME $INTRIM_SEAWEEDFS_IMG

# Push interim image to registry for multi-arch build
$ENGINE push $INTRIM_SEAWEEDFS_IMG

# Clean up intermediate container and temporary files
$ENGINE rm $CONTAINER_NAME --force

echo "Platforms: ${PLATFORMS}"
$ENGINE buildx create --name multiarch-builder --driver docker-container --use 2>/dev/null || $ENGINE buildx use multiarch-builder
$ENGINE buildx build --no-cache --platform ${PLATFORMS} --load -f Dockerfile -t ${FINAL_SEAWEEDFS_IMG} .
