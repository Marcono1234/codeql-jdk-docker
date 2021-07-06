@REM Build image, then start container (with `--rm` to remove it once finished)
docker build . -t codeql-jdk && docker container run --rm --name "codeql-jdk-db-build" --mount type=bind,source="%cd%/databases",target=/codeql-jdk/codeql-jdk-databases codeql-jdk %*
