#!/bin/sh

echo 'Injecting runtime configuration...'
sed -i -e "s|db_username|${DB_USERNAME}|" -e "s|db_password|${DB_PASSWORD}|" -e "s|db_host|${DB_HOST}|" conf/openfire.xml
sed -i -e "s|cluster_members|${CLUSTER_MEMBERS}|" conf/cluster.xml
sed -i -e "s|auth_key|${AUTH_KEY}|" conf/secret
sed -i -e "s|log_size|${LOG_SIZE}|" lib/log4j2.xml

echo 'Logging image build information...'
cat build_information.json >> logs/info.log

export OPENFIRE_OPTS="-XX:MaxMetaspaceSize=$METASPACE_SIZE \
                      -XX:MaxDirectMemorySize=$DIRECTMEM_SIZE \
                      -XX:+UseG1GC \
                      -XX:+UseStringDeduplication \
                      -XX:NativeMemoryTracking=summary \
                      -XX:+HeapDumpOnOutOfMemoryError \
                      -Xlog:::time,level,tags \
                      -Xlog:gc:logs/gc.log:time \
                      -Xlog:age=debug \
                      --add-modules java.se \
                      --add-exports java.base/jdk.internal.ref=ALL-UNNAMED \
                      --add-opens java.base/java.lang=ALL-UNNAMED \
                      --add-opens java.base/java.nio=ALL-UNNAMED \
                      --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
                      --add-opens java.management/sun.management=ALL-UNNAMED \
                      --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED \
                      $EXTRA_OPENFIRE_OPTS"

echo 'Running Liquibase migrator...'
if [ -z "${LIQUIBASE_CONTEXTS}" ]
then
    echo $'Migrator not run because LIQUIBASE_CONTEXTS has not been set.\n' >> logs/liquibase.log
else
    java -jar liquibase/unicorn-openfire-liquibase-migrator.jar \
        --driver=com.mysql.cj.jdbc.Driver \
        --changeLogFile=resources/database/changelog.xml \
        --url="${DB_HOST}?useSSL=false&useUnicode=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        --contexts="${LIQUIBASE_CONTEXTS}" \
        update >> logs/liquibase.log 2>&1
fi

echo 'Launching Openfire...'
bin/openfire.sh
