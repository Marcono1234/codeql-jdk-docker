FROM ubuntu:focal

WORKDIR /codeql-jdk

# See https://github.com/openjdk/jdk/blob/master/doc/building.md

# Install required tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends \
    build-essential autoconf make zip unzip file \
    # Not used by the JDK build, but needed for building CodeQL database
    wget git

# Install required libraries
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends \
    libfreetype6-dev \
    libcups2-dev \
    libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev \
    libasound2-dev \
    libffi-dev \
    libfontconfig1-dev

# Install boot JDK
ARG BOOT_JDK_URL="https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1+1/OpenJDK18U-jdk_x64_linux_hotspot_18.0.2.1_1.tar.gz"
RUN apt-get -y install ca-certificates \
    && wget --no-verbose "${BOOT_JDK_URL}" --output-document=boot-jdk.tar.gz \
    && mkdir boot-jdk \
    # --strip-components because all JDK files are nested inside a directory in the archive
    && tar -xzf boot-jdk.tar.gz -C boot-jdk --strip-components=1 \
    && rm boot-jdk.tar.gz

# Set up CodeQL CLI
ARG CODEQL_CLI_VERSION=2.10.5
RUN apt-get -y install ca-certificates \
    && wget --no-verbose "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_CLI_VERSION}/codeql-linux64.zip" --output-document=codeql-linux64.zip \
    && unzip -q -d codeql-cli codeql-linux64.zip \
    && rm codeql-linux64.zip

# Copy scripts
# Do this last to allow modifying scripts without having to rebuild all other layers
COPY ./docker_scripts/* ./docker_scripts/

ENTRYPOINT ["./docker_scripts/create_database.sh"]
CMD ["--jdk-git-repo", "https://github.com/openjdk/jdk19u"]
