@REM Create output directory; abort if directory cannot be created (e.g. when file with this name exists)
IF NOT EXIST "databases/" mkdir databases || EXIT 1

@REM Build image, then start container (with `--rm` to remove it once finished)
docker build .. -t codeql-jdk:20-linux --build-arg BOOT_JDK_URL=https://github.com/adoptium/temurin19-binaries/releases/download/jdk-19.0.2+7/OpenJDK19U-jdk_x64_linux_hotspot_19.0.2_7.tar.gz && docker container run --rm --name "codeql-jdk-20-linux-db-build" --mount type=bind,source="%cd%/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk:20-linux --jdk-git-repo https://github.com/openjdk/jdk20u --jdk-version-name 20-linux %*
