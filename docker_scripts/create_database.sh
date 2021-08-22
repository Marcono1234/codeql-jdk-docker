#!/bin/bash
set -e

DB_PARENT_DIR="codeql-jdk-databases"
if [ ! -d "${DB_PARENT_DIR}" ]; then
    echo "Database output directory '${DB_PARENT_DIR}' is not specified as Docker volume"
    exit 1
fi

# Parse arguments (see https://stackoverflow.com/a/14203146)
# Checking if variable is set uses https://stackoverflow.com/a/13864829
while [[ $# -gt 0 ]]; do
  key="$1"

  case "$key" in
    --jdk-git-repo)
      if [ -z "${REPO_URL+x}" ]; then
        REPO_URL="$2"
      else
        echo "Duplicate 'jdk-git-repo' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    --jdk-commit-sha)
      if [ -z "${COMMIT_SHA+x}" ]; then
        COMMIT_SHA="$2"
      else
        echo "Duplicate 'jdk-commit-sha' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    --memory-limit)
      if [ -z "${MEMORY_LIMIT+x}" ]; then
        MEMORY_LIMIT="$2"
      else
        echo "Duplicate 'memory-limit' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    --cpu-cores)
      if [ -z "${CPU_CORES+x}" ]; then
        CPU_CORES="$2"
      else
        echo "Duplicate 'cpu-cores' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    --make-target)
      if [ -z "${MAKE_TARGET+x}" ]; then
        MAKE_TARGET="$2"
      else
        echo "Duplicate 'make-target' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    --codeql-db-lang)
      if [ -z "${DB_LANG+x}" ]; then
        DB_LANG="$2"
      else
        echo "Duplicate 'codeql-db-lang' argument"
        exit 1
      fi
      shift # past parameter
      shift # past value
      ;;
    *)
      echo "Unknown parameter '$key'"
      exit 1
      ;;
  esac
done

if [ -z "${REPO_URL+x}" ]; then
    echo "Missing 'jdk-git-repo' argument"
    exit 1
fi

if [ -z "${DB_LANG+x}" ]; then
    echo "No CodeQL database language set; using Java"
    DB_LANG="java"
fi

DB_DIR_NAME="codeql-jdk-${DB_LANG}-db"
DB_PATH="${DB_PARENT_DIR}/${DB_DIR_NAME}"
if [ -e "${DB_PATH}" ]; then
    echo "Database '${DB_DIR_NAME}' already exists"
    exit 1
fi

mkdir jdk
cd jdk

if [ -z "${COMMIT_SHA+x}" ]; then
    git clone --depth 1 "$REPO_URL" .
else
    git clone --no-checkout "$REPO_URL" .
    git checkout "$COMMIT_SHA"
fi

# Specify build and host OS to avoid detection of WSL as Windows
CONF_COMMAND="configure --build=x86_64-unknown-linux-gnu --host=x86_64-unknown-linux-gnu"

# Build performance customization
# https://github.com/openjdk/jdk/blob/master/doc/building.md#build-performance
# Memory limit in MB
if [ -n "${MEMORY_LIMIT+x}" ]; then
    echo "Using custom memory limit ${MEMORY_LIMIT}"
    CONF_COMMAND="${CONF_COMMAND} --with-memory-size=${MEMORY_LIMIT}"
fi

if [ -n "${CPU_CORES+x}" ]; then
    # Note: Currently JDK "Build performance summary" shows number of parallel
    # jobs as "Cores to use"; its value is based on cores count and memory
    echo "Using custom CPU cores count ${CPU_CORES}"
    CONF_COMMAND="${CONF_COMMAND} --with-num-cores=${CPU_CORES}"
fi

# Create JDK build configuration
bash ${CONF_COMMAND}

# See https://github.com/openjdk/jdk/blob/master/doc/building.md#running-make
if [ -z "${MAKE_TARGET+x}" ]; then
    # 'java' target compiles all Java code
    echo "No make target set; using 'java'"
    MAKE_TARGET="java"
fi

# Build database in temp directory and afterwards copy result to mounted dir
# to reduce IO in mounted dir for better performance on WSL
mkdir ../db-build-temp
../codeql-cli/codeql/codeql database create "--language=${DB_LANG}" --source-root=. "--command=make ${MAKE_TARGET}" "../db-build-temp"
cp --recursive ../db-build-temp "../${DB_PATH}"

echo "Finished creating database '${DB_DIR_NAME}'"
