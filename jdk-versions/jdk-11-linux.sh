#!/bin/bash
set -e

# Create output directory
mkdir -p databases
# Build image, then start container (with `--rm` to remove it once finished)
docker build .. -t codeql-jdk:11-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.16.1+1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.16.1_1.tar.gz
docker container run --rm --name "codeql-jdk-11-linux-db-build" --mount type=bind,source="$(pwd)/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:11-linux --jdk-git-repo https://github.com/openjdk/jdk11u --jdk-version-name 11-linux "$@"
