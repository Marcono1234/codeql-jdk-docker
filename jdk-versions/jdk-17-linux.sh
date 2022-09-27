#!/bin/bash
set -e

# Create output directory
mkdir -p databases
# Build image, then start container (with `--rm` to remove it once finished)
docker build .. -t codeql-jdk:17-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4.1+1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.4.1_1.tar.gz
docker container run --rm --name "codeql-jdk-17-linux-db-build" --mount type=bind,source="$(pwd)/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:17-linux --jdk-git-repo https://github.com/openjdk/jdk17u --jdk-version-name 17-linux "$@"
