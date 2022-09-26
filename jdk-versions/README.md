# JDK version build scripts
This directory contains convenience build scripts for creating databases for the Java code of the latest commits of specific JDK release versions. Currently supported are:
- `jdk8u`: Cloned from [adoptium/jdk8u](https://github.com/adoptium/jdk8u)
- `jdk11u`: Cloned from [openjdk/jdk11u](https://github.com/openjdk/jdk11u)
- `jdk17u`: Cloned from [openjdk/jdk17u](https://github.com/openjdk/jdk17u)
- _latest release_: Cloned from [openjdk/jdk19u](https://github.com/openjdk/jdk19u)

The build scripts support the command line arguments for tweaking build performance, as [specified by the README](/README.md#build-configuration).

At the moment only the Linux variant of the JDK can be build, building the Windows variant is not supported.
