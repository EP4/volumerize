#!/bin/bash

set -o errexit

readonly VOLUMERIZE_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

readonly PARAMETER_PROXY='$@'

cat > ${VOLUMERIZE_SCRIPT_DIR}/backup <<_EOF_
#!/bin/bash

set -o errexit

if [ "${VOLUMERIZE_MYSQL_BACKUPS}" = 'true' ]; then
  mysqldump --single-transaction --routines --events --triggers --add-drop-table --extended-insert -u ${VOLUMERIZE_MYSQL_USER} -h ${VOLUMERIZE_MYSQL_HOST} -p${VOLUMERIZE_MYSQL_PASSWORD} --all-databases | gzip -9 > ${VOLUMERIZE_SOURCE}/mysqldump/db_\$(date +"%H:%M_%d-%m-%Y").sql.gz
fi

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers

rm -rf ${VOLUMERIZE_SOURCE}/mysqldump/db_*

_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupIncremental <<_EOF_
#!/bin/bash

set -o errexit

if [ "${VOLUMERIZE_MYSQL_BACKUPS}" = 'true' ]; then
  mysqldump --single-transaction --routines --events --triggers --add-drop-table --extended-insert -u ${VOLUMERIZE_MYSQL_USER} -h ${VOLUMERIZE_MYSQL_HOST} -p${VOLUMERIZE_MYSQL_PASSWORD} --all-databases | gzip -9 > ${VOLUMERIZE_SOURCE}/mysqldump/db_\$(date +"%H:%M_%d-%m-%Y").sql.gz
fi

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} incremental ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers

rm -rf ${VOLUMERIZE_SOURCE}/mysqldump/db_*
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupFull <<_EOF_
#!/bin/bash

set -o errexit

if [ "${VOLUMERIZE_MYSQL_BACKUPS}" = 'true' ]; then
  mysqldump --single-transaction --routines --events --triggers --add-drop-table --extended-insert -u ${VOLUMERIZE_MYSQL_USER} -h ${VOLUMERIZE_MYSQL_HOST} -p${VOLUMERIZE_MYSQL_PASSWORD} --all-databases | gzip -9 > ${VOLUMERIZE_SOURCE}/mysqldump/db_\$(date +"%H:%M_%d-%m-%Y").sql.gz
fi

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers

rm -rf ${VOLUMERIZE_SOURCE}/mysqldump/db_*
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/restore <<_EOF_
#!/bin/bash

set -o errexit

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} restore --force ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers

if [ "${VOLUMERIZE_MYSQL_BACKUPS}" = 'true' ]; then
  tar -xzOf ${VOLUMERIZE_TARGET}/mysqldump/\$(ls -dt ${VOLUMERIZE_TARGET}/mysqldump/db_* | head -1) | mysql -u ${VOLUMERIZE_MYSQL_USER} -h ${VOLUMERIZE_MYSQL_HOST} -p${VOLUMERIZE_MYSQL_PASSWORD}
  #rm -rf ${VOLUMERIZE_TARGET}/mysqldump/db_*
fi

_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/verify <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} verify --compare-data ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/cleanup <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} cleanup ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-older-than <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-older-than ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-all-but-n-full <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-all-but-n-full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-all-inc-of-but-n-full <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-all-inc-of-but-n-full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_TARGET}
_EOF_

FILENAME_VARIABLE='$filename'

cat > ${VOLUMERIZE_SCRIPT_DIR}/cleanCacheLocks <<_EOF_
#!/bin/bash

set -o errexit

find /volumerize-cache/ -maxdepth 2 -type f -name lockfile.lock | while read filename ; do fuser -s ${FILENAME_VARIABLE} || rm -fv ${FILENAME_VARIABLE} ; done
_EOF_
