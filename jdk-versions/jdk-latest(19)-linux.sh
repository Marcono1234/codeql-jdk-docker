#!/bin/bash
set -e

# Create output directory
mkdir -p databases
# Build image, then start container (with `--rm` to remove it once finished)
docker build .. -t codeql-jdk:19-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1+1/OpenJDK18U-jdk_x64_linux_hotspot_18.0.2.1_1.tar.gz
docker container run --rm --name "codeql-jdk-19-linux-db-build" --mount type=bind,source="$(pwd)/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:19-linux --jdk-git-repo https://github.com/openjdk/jdk19u --jdk-version-name 19-linux "$@"
