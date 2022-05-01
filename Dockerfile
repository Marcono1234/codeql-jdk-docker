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
ARG BOOT_JDK_VERSION=17
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends \
    "openjdk-${BOOT_JDK_VERSION}-jdk-headless"

# Set up CodeQL CLI
ARG CODEQL_CLI_VERSION=2.9.0
RUN wget -q "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_CLI_VERSION}/codeql-linux64.zip" --output-document=codeql-linux64.zip \
    && unzip -q -d codeql-cli codeql-linux64.zip \
    && rm codeql-linux64.zip

# Copy scripts
# Do this last to allow modifying scripts without having to rebuild all other layers
COPY ./docker_scripts/* ./docker_scripts/

ENTRYPOINT ["./docker_scripts/create_database.sh"]
CMD ["--jdk-git-repo", "https://github.com/openjdk/jdk18u"]
