# codeql-jdk-docker
Unofficial scripts and Docker configuration for building [CodeQL](https://codeql.github.com/docs/) databases for the OpenJDK.  
The created databases can then for example be loaded and analyzed using the [Visual Studio Code CodeQL extension](https://codeql.github.com/docs/codeql-for-visual-studio-code/analyzing-your-projects/).

:warning: Your usage of CodeQL and the created databases has to adhere to the [GitHub CodeQL Terms and Conditions](https://securitylab.github.com/tools/codeql/license/).

## Requirements
- OS: Windows 10, Linux (not tested)
- CPU architecture: 64-bit
- Docker ([Docker Desktop](https://www.docker.com/products/docker-desktop))
- RAM: 8GB or more

See also [OpenJDK Build Hardware Requirements](https://github.com/openjdk/jdk/blob/master/doc/building.md#build-hardware-requirements).

## Usage
This project provides convenience scripts for creating a CodeQL database for the Java code of the OpenJDK:
- Windows: [`build_database.cmd`](./build_database.cmd)
- Linux: [`build_database.sh`](./build_database.sh)

At the moment they use CodeQL CLI 2.5.7 and build a Java database for the latest https://github.com/openjdk/jdk16u commit.

These scripts can be executed as is (assuming that Docker has already been started). They perform the following tasks:
1. Build the Docker image (named `codeql-jdk`)
2. Clone the JDK source code
3. Build the CodeQL database and copy it to the `databases` folder of the current directory

Note: Building the Docker image, the JDK and the CodeQL database are all resource and time intensive tasks. In total they might take up to an hour (depends on your network connection and hardware).

:information_source: 3 to 4GB of memory might suffice for the Docker container, however a memory limit should be specified for the JDK build using `--memory-limit` (see ["Build configuration" section](#build-configuration)), otherwise the build can get stuck and fail.

### Docker image configuration
The Dockerfile uses [build-time variables](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) for configuration.
- `BOOT_JDK_VERSION`: Version of the [boot JDK](https://github.com/openjdk/jdk/blob/master/doc/building.md#boot-jdk-requirements), e.g. `16`  
The value is used for the package retrieved from the package repository of Ubuntu, make sure that a package for this version exists.
- `CODEQL_CLI_VERSION`: Version of [CodeQL CLI](https://github.com/github/codeql-cli-binaries/releases) to use for building the database, e.g. `2.5.7`

### Build configuration
The Docker image has a build script as entry point which allows customizing how the JDK and the CodeQL database is built.
The arguments are passed as additional arguments to [`docker container run`](https://docs.docker.com/engine/reference/commandline/container_run/).
Additionally the arguments can be used with the convenience scripts mentioned in the ["Usage" section](#usage).

Arguments have the format <code>--<i>param</i> <i>value</i></code>

- `--jdk-git-repo` (required)  
URI of the Git repository from which the JDK source code should be cloned. When choosing the JDK version to build, the following has to be considered:
  - A matching boot JDK has to be choosen (see ["Docker image configuration" section](#docker-image-configuration))
  - CodeQL CLI has to support the Java version. The CodeQL CLI version might have to be adjusted  (see ["Docker image configuration" section](#docker-image-configuration)).  
    CodeQL CLI might not support building the latest JDK yet, prefer JDK update projects such as [jdk16u](https://github.com/openjdk/jdk16u).
  - The Dockerfile is currently configured for the default JDK built by the convenience scripts of this project. Other JDKs might have different dependencies, consult the [JDK build instructions](https://github.com/openjdk/jdk/blob/master/doc/building.md) and adjust the Dockerfile if problems occur.
  - Since the JDK build tools are part of the JDK repository, the choice of the JDK version affects which of the other build arguments are supported and how they behave.
- `--jdk-commit-sha`  
Git commit hash (or branch name) of the commit to build. If not specified the latest commit of the active branch of the remote Git repository is built.  
See also the considerations for picking the JDK version described above for the `--jdk-git-repo` parameter.
- `--memory-limit`  
Specifies the memory limit in MB for the JDK build within the container. The JDK build tools will use the maximum memory available to the container if not specified.
It is recommended to specify a custom limit because the JDK build tools do not account for CodeQL CLI running during the build, causing the JDK build to slow down or even fail.
Creating a container with ~4GB, and setting a memory limit of ~2GB for the JDK build seems to work fine.  
Also have a look at the JDK [Build Hardware Requirements](https://github.com/openjdk/jdk/blob/master/doc/building.md#build-hardware-requirements) and [Build Performance guide](https://github.com/openjdk/jdk/blob/master/doc/building.md#build-performance). When using WSL2 on Windows, tuning the [WSL 2 Settings](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wsl-2-settings) might help as well.
- `--cpu-cores`  
Specifies the number of CPU cores the JDK build is allowed to use. The JDK build tools will use all cores dedicated to the container by default.
Also have a look at the JDK [Build Performance guide](https://github.com/openjdk/jdk/blob/master/doc/building.md#build-performance). When using WSL2 on Windows, tuning the [WSL 2 Settings](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wsl-2-settings) might help as well.
- `--make-target`  
Specifies the [`make` target](https://github.com/openjdk/jdk/blob/master/doc/building.md#running-make) for the JDK build. By default the `java` target is executed, compiling all Java code of the JDK.
- `--codeql-db-lang`  
Specifies the programming language for which CodeQL CLI shoud create the database, have a look at the [CodeQL CLI documentation](https://codeql.github.com/docs/codeql-cli/creating-codeql-databases/#running-codeql-database-create) for a list of supported programming languages. By default the database is created for Java source code.
When choosing a different programming language it might be necessary to specify a different `--make-target`.  
Note: The chosen database language influences the name of the created database folder.
