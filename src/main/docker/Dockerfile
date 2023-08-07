FROM registry.access.redhat.com/ubi8/ubi:8.5

LABEL Name="Unicorn Openfire Notifications Server" \
      Description="Openfire container with clustering enabled and Gamesys add-ons" \
      Maintainer="Unicorn <unicornteamleads@gamesys.co.uk>" \
      Vendor="Gamesys" \
      License="Proprietary"

ARG JAVA_PACKAGE=java-11-openjdk
ARG USER_NAME=openfire
ARG USER_ID=500
ARG USER_GID=500
ARG OPENFIRE_HOME=/opt/openfire
ARG OPENFIRE_BIN_DIR=${OPENFIRE_HOME}/bin
ARG OPENFIRE_LIB_DIR=${OPENFIRE_HOME}/lib
ARG OPENFIRE_CONF_DIR=${OPENFIRE_HOME}/conf
ARG OPENFIRE_PLUGINS_DIR=${OPENFIRE_HOME}/plugins
ARG OPENFIRE_DB_RESOURCES_DIR=${OPENFIRE_HOME}/resources/database
ARG OPENFIRE_LIQUIBASE_DIR=${OPENFIRE_HOME}/liquibase

# CVE-2021-45046
ENV LOG4J_FORMAT_MSG_NO_LOOKUPS=true
RUN echo "LOG4J_FORMAT_MSG_NO_LOOKUPS=true" >> /etc/environment

COPY ./yum/gamesys_packages.repo /etc/yum.repos.d/

RUN yum -y update && \
    yum -y install ${JAVA_PACKAGE} && \
    yum -y install openfire-4.5.2 && \
    yum clean all && \
    rm /opt/openfire/plugins/search.jar && \
    rm /opt/openfire/lib/log4j*.jar && \
    rm -rf /opt/openfire/jre/ && \
    rm -rf /tmp/*

WORKDIR ${OPENFIRE_HOME}

COPY ./bin/ ${OPENFIRE_BIN_DIR}/
COPY ./lib/ ${OPENFIRE_LIB_DIR}/
COPY ./conf/ ${OPENFIRE_CONF_DIR}/
COPY ./database/ ${OPENFIRE_DB_RESOURCES_DIR}/
COPY ./build_information.json ${OPENFIRE_HOME}/

# File names of Log4J JARS are renamed to satisfy xmppserver.jar. This was done as part
# addressing the Log4J-Shell exploit. However, this temporary measure needs to be
# replaced with a proper fix once the Log4J vulnerability has been tackled. CVE-2021-45046
COPY ./log4j-api*.jar ${OPENFIRE_LIB_DIR}/log4j-api-2.11.2.jar
COPY ./log4j-core*.jar ${OPENFIRE_LIB_DIR}/log4j-core-2.11.2.jar
COPY ./log4j-slf4j-impl*.jar ${OPENFIRE_LIB_DIR}/log4j-slf4j-impl-2.11.2.jar
COPY ./unicorn-*plugin*.jar ${OPENFIRE_PLUGINS_DIR}/

COPY ./unicorn-openfire-liquibase-migrator*.jar ${OPENFIRE_LIQUIBASE_DIR}/unicorn-openfire-liquibase-migrator.jar
COPY ./unicorn-openfire-jwt-auth-provider*.jar ${OPENFIRE_LIB_DIR}/
COPY ./unicorn-openfire-chat-token-auth-provider*.jar ${OPENFIRE_LIB_DIR}/
COPY ./unicorn-openfire-third-party-dependencies*.jar ${OPENFIRE_LIB_DIR}/

RUN groupadd --gid ${USER_GID} ${USER_NAME} && \
    useradd --uid ${USER_ID} --gid ${USER_GID} ${USER_NAME} && \
    chown -R ${USER_NAME} ${OPENFIRE_HOME} && \
    chmod +x ${OPENFIRE_BIN_DIR}/launch.sh
USER ${USER_NAME}

ENV LOG_SIZE=262144KB

ENTRYPOINT ["bin/launch.sh"]
