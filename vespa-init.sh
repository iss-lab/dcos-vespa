#!/bin/bash

set -e

export HOME=/mnt/mesos/sandbox/
VESPA_CONFIGSERVERS="config-0-node.${FRAMEWORK_HOST}"
COUNTER=1
while [ $COUNTER -lt $COUNT ]; do
VESPA_CONFIGSERVERS="${VESPA_CONFIGSERVERS},config-${COUNTER}-node.${FRAMEWORK_HOST}"
let COUNTER=COUNTER+1 
done 
export VESPA_CONFIGSERVERS
export VESPA_HOSTNAME="${TASK_NAME}.${FRAMEWORK_HOST}"

hostname ${VESPA_HOSTNAME}

CONF=/opt/vespa/conf/vespa/default-env.txt
rm -f ${CONF}
touch ${CONF}
echo "fallback VESPA_HOME /opt/vespa" >> ${CONF}
echo "override VESPA_UNPRIVILEGED no" >> ${CONF}
echo "override VESPA_USER root" >> ${CONF}
echo "override VESPA_CONFIGSERVERS ${VESPA_CONFIGSERVERS}" >> ${CONF}
echo "override VESPA_HOSTNAME ${VESPA_HOSTNAME}" >> ${CONF}
# echo 'override VESPA_LOG_LEVEL "all -debug -spam"' >> ${CONF}
# echo "override VESPA_LOG_LEVEL all" >> ${CONF}

cat ${CONF}

mkdir -p $MESOS_SANDBOX/vespa/var
mkdir -p $MESOS_SANDBOX/vespa/logs
mkdir -p $MESOS_SANDBOX/vespa/conf
cp -R /opt/vespa/conf/* $MESOS_SANDBOX/vespa/conf/
rm -rf /opt/vespa/var
rm -rf /opt/vespa/logs
rm -rf /opt/vespa/conf
cd /opt/vespa
ln -fs $MESOS_SANDBOX/vespa/var var
ln -fs $MESOS_SANDBOX/vespa/logs logs
ln -fs $MESOS_SANDBOX/vespa/conf conf
cd $MESOS_SANDBOX

if [[ $CONTENT_COUNT -eq 0 && $CONTAINER_COUNT -eq 0 ]]; then
  VESPA_MODE=all
fi

echo "Vespa run mode: ${VESPA_MODE}"

case $VESPA_MODE in
    all)
        /opt/vespa/bin/vespa-start-configserver
        /opt/vespa/bin/vespa-start-services
        ;;
    config)
        /opt/vespa/bin/vespa-start-configserver
        /opt/vespa/bin/vespa-start-services
        ;;
    container)
        /opt/vespa/bin/vespa-start-services
        ;;
    content)
        /opt/vespa/bin/vespa-start-services
        ;;
    *)
        echo "No VESPA_MODE defined."
        exit 1
        ;;
esac

touch $MESOS_SANDBOX/vespa/logs/vespa/vespa.log
VESPA_CMD="tail -f $MESOS_SANDBOX/vespa/logs/vespa/vespa.log"

exec ${VESPA_CMD}