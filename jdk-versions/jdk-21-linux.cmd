@REM Create output directory; abort if directory cannot be created (e.g. when file with this name exists)
IF NOT EXIST "databases/" mkdir databases || EXIT 1

@REM Build image, then start container (with `--rm` to remove it once finished)
docker build .. -t codeql-jdk:21-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1+12/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz && docker container run --rm --name "codeql-jdk-21-linux-db-build" --mount type=bind,source="%cd%/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:21-linux --jdk-git-repo https://github.com/openjdk/jdk21u --jdk-version-name 21-linux %*
