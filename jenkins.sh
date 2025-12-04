#!/bin/bash
set -e  # exit on error

# Docker login (token must be in env variable)
echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Check if buildx builder exists
builder_exists=$(docker buildx ls | grep -w "mybuilder" || true)
echo "checking builder: $builder_exists"
if [ -z "$builder_exists" ]; then
    echo "Creating buildx builder 'mybuilder'..."
    docker buildx create --use --name mybuilder
    docker buildx inspect --bootstrap
else
    echo "Using existing builder 'mybuilder'"
    docker buildx use mybuilder
fi

echo "Build multi-platform image"
IMAGE_TAG="raw101/multiarchplatform:${BUILD_NUMBER}"

echo "Building multi-platform image: $IMAGE_TAG"

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "$IMAGE_TAG" \
    --push .

echo "Testing multi-platform image: $IMAGE_TAG"
# Inspect manifest run this command after images exits on your platform to check docker images multi platform or not
# docker buildx imagetools inspect "$IMAGE_TAG"
# Run container and test
echo "Running container from image: $IMAGE_TAG"
docker run -d -p 8001:3000 "$IMAGE_TAG"
echo "Waiting for container to start..."
sleep 10
echo "Checking container response..."
curl --head http://localhost:8001
# Clean up
echo "Stopping and removing container..."
docker stop $(docker ps -q)