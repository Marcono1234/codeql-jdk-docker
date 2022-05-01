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
    --jdk-version-name)
      if [ -z "${JDK_VERSION_NAME+x}" ]; then
        JDK_VERSION_NAME="$2"
      else
        echo "Duplicate 'jdk-version-name' argument"
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

echo "Using CodeQL CLI $(./codeql-cli/codeql/codeql version --format=terse)"
if [ -z "${DB_LANG+x}" ]; then
    echo "No CodeQL database language set; using Java"
    DB_LANG="java"
fi

mkdir jdk
cd jdk

echo "Cloning JDK repository ${REPO_URL}"
if [ -z "${COMMIT_SHA+x}" ]; then
    git clone --depth 1 "$REPO_URL" .
else
    # Try shallow fetch of specific commit (might not be supported by remote repository)
    # See https://stackoverflow.com/a/43136160
    git init
    git remote add origin "${REPO_URL}"

    EXIT_CODE=0
    git fetch --depth 1 origin "${COMMIT_SHA}" || EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
        git checkout FETCH_HEAD
    else
        echo "Failed performing shallow fetch; trying full fetch instead"
        git fetch origin
        git checkout "$COMMIT_SHA"
    fi
fi

# Get the actual commit SHA because COMMIT_SHA might either not be
# specified or be a branch name
ACTUAL_COMMIT_SHA="$(git rev-parse --short=10 HEAD)"

if [ -z "${JDK_VERSION_NAME+x}" ]; then
    DB_DIR_NAME="codeql-jdk-${DB_LANG}-db-${ACTUAL_COMMIT_SHA}"
else
    DB_DIR_NAME="codeql-jdk-${JDK_VERSION_NAME}-${DB_LANG}-db-${ACTUAL_COMMIT_SHA}"
fi

DB_PATH="${DB_PARENT_DIR}/${DB_DIR_NAME}"
# Use `..` because current directory is "jdk"
if [ -e "../${DB_PATH}" ]; then
    echo "Database '${DB_DIR_NAME}' already exists"
    exit 1
fi

echo "Building JDK commit ${ACTUAL_COMMIT_SHA}"

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
    # See https://bugs.openjdk.java.net/browse/JDK-8270438
    echo "Using custom CPU cores count ${CPU_CORES}"
    CONF_COMMAND="${CONF_COMMAND} --with-num-cores=${CPU_CORES}"
fi

echo ""
echo "----- Creating JDK build configuration -----"

# Create JDK build configuration
bash ${CONF_COMMAND}

# See https://github.com/openjdk/jdk/blob/master/doc/building.md#running-make
if [ -z "${MAKE_TARGET+x}" ]; then
    # 'java' target compiles all Java code
    echo "No make target set; using 'java'"
    MAKE_TARGET="java"
fi

echo ""
echo "----- Building JDK -----"

# Build database in temp directory and afterwards copy result to mounted dir
# to reduce IO in mounted dir for better performance on WSL
mkdir ../db-build-temp
../codeql-cli/codeql/codeql database create "--language=${DB_LANG}" --source-root=. "--command=make ${MAKE_TARGET}" "../db-build-temp"
cp --recursive ../db-build-temp "../${DB_PATH}"

echo ""
echo "Finished creating database '${DB_DIR_NAME}'"
