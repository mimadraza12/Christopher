# syntax=docker/dockerfile:1.7
#
# Liquibase + ClickHouse image for Christopher.
#
# Versions are pinned together on purpose: the Arenadata extension 0.8.x is built
# for Liquibase 4.33.0 + clickhouse-jdbc 0.9.4. Change all three together or not at all.
#
# The extension is built from the tagged source so we don't depend on where (or
# whether) a given tag is published to Maven Central. Its runtime dependencies
# (clickhouse-jdbc and transitive jars) are copied next to it.

ARG LIQUIBASE_VERSION=4.33.0
ARG EXTENSION_TAG=0.8.3-arenadata

# ---------------------------------------------------------------- build stage
FROM maven:3.9.9-eclipse-temurin-17 AS build
ARG EXTENSION_TAG
WORKDIR /build

ADD https://github.com/arenadata/liquibase-clickhouse/archive/refs/tags/${EXTENSION_TAG}.tar.gz /build/src.tar.gz
RUN tar -xzf src.tar.gz --strip-components=1 && rm src.tar.gz

# 1) the extension jar
# 2) its runtime deps, excluding liquibase-core (scope "provided") and jars Liquibase
#    already ships in internal/lib (snakeyaml, slf4j-api, commons-io): duplicates conflict
RUN mvn -B -q -DskipTests \
        -Dmaven.compiler.source=11 -Dmaven.compiler.target=11 \
        package \
 && mvn -B -q dependency:copy-dependencies \
        -DincludeScope=runtime \
        -DexcludeArtifactIds=snakeyaml,slf4j-api,commons-io \
        -DoutputDirectory=/out/lib \
 && cp target/liquibase-clickhouse-*.jar /out/lib/

# Cluster mode: the extension reads liquibaseClickhouse.conf from the CLASSPATH.
# A loose .conf in /liquibase/lib is not on the classpath, so pack it into a jar.
COPY liquibaseClickhouse.conf /build/conf/liquibaseClickhouse.conf
RUN cd /build/conf && jar cf /out/lib/zz-christopher-cluster-conf.jar liquibaseClickhouse.conf

# ---------------------------------------------------------------- runtime
FROM liquibase/liquibase:${LIQUIBASE_VERSION}
ARG EXTENSION_TAG

LABEL org.opencontainers.image.title="christopher-liquibase" \
      org.opencontainers.image.description="Liquibase 4.33.0 + liquibase-clickhouse ${EXTENSION_TAG} (cluster mode) + clickhouse-jdbc 0.9.4"

COPY --from=build /out/lib/ /liquibase/lib/

# Changelog is mounted / checked out here in every mode. Changeset identity includes
# the file path RELATIVE to the search path, so this must stay stable.
ENV LIQUIBASE_SEARCH_PATH=/liquibase/changelog \
    LIQUIBASE_COMMAND_CHANGELOG_FILE=changelog-master.yaml \
    LIQUIBASE_SHOW_BANNER=false \
    LIQUIBASE_ANALYTICS_ENABLED=false

WORKDIR /liquibase
