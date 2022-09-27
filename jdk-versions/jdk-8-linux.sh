#!/bin/bash
set -e

# Create output directory
mkdir -p databases
# Build image, then start container (with `--rm` to remove it once finished)
# Note: https://hg.openjdk.java.net/jdk8/jdk8/raw-file/tip/README-builds.html#bootjdk says JDK 7 should
# be used as boot JDK, but using JDK 8 seems to work as well
docker build .. -t codeql-jdk:8-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u345-b01/OpenJDK8U-jdk_x64_linux_hotspot_8u345b01.tar.gz
# Uses Adoptium repository because https://github.com/openjdk/jdk8u is not updated anymore
# EDIT: Apparently openjdk/jdk8u is updated again?
docker container run --rm --name "codeql-jdk-8-linux-db-build" --mount type=bind,source="$(pwd)/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:8-linux --jdk-git-repo https://github.com/adoptium/jdk8u --make-target all --jdk-version-name 8-linux "$@"
