#
# HRB basic setting.
#

# Paths
HRB_HOME=${HRB_HOME:-"$(dirname $(cd -P -- "$(dirname -- ${BASH_SOURCE:-$0})" && pwd -P))"}

# HRB
HRB_BIN_DIR=${HRB_HOME}/bin
HRB_SUB_COMMAND_DIR=${HRB_BIN_DIR}/command
HRB_CONF_DIR=${HRB_HOME}/conf
HRB_DB_DIR=${HRB_HOME}/db
HRB_LIB_DIR=${HRB_HOME}/lib
HRB_TMP_DIR=${HRB_TMP_DIR:-"${HRB_HOME}/tmp"}
HRB_LOG_DIR=${HRB_LOG_DIR:-"${HRB_HOME}/log"}

HRB_MAIL_TO=${HRB_MAIL_TO:-"haikikyou81@gmail.com"}

# debug: 0, info: 1, warn:2, error:3
HRB_LOG_LEVEL=${HRB_LOG_LEVEL:-1}
# If the path is empty, output to stdout. Otherwise file.
#HRB_LOG_PATH=${HRB_LOG_PATH:-""}
HRB_LOG_PATH=${HRB_LOG_PATH:-"${HRB_LOG_DIR}/hrbridge.log.$(date +'%Y%m%d')"}
# If the path is empty, output to stdout. Otherwise file.
#HRB_SQOOP_LOG_PATH=${HRB_SQOOP_LOG_PATH:-"/dev/null"}
HRB_SQOOP_LOG_PATH=${HRB_SQOOP_LOG_PATH:-"${HRB_LOG_DIR}/sqoop.log.$(date +'%Y%m%d')"}

# Database setting
. ${HRB_CONF_DIR}/database${HRB_ENVIRONMENT:+"-${HRB_ENVIRONMENT}"}.properties
DATABASE_HOST=${DatabaseHost:-"localhost"}
DATABASE_DATABASE=${DatabaseDatabase:-""}
DATABASE_USER=${DatabaseUser:-""}
DATABASE_PASS=${DatabasePassword:-""}

# Hive
HIVE_DATABASE_DIR=/user/hive/warehouse
HIVE_EXPORT_DATABASE=${HIVE_EXPORT_DATABASE:-"default.db"}

# Add mysql-connector-J to HADOOP_CLASSPATH
HRB_MYSQL_CONNECTOR=$(ls ${HRB_LIB_DIR}/mysql-* | sort -r | head -1 | sed -e s#.*/##)
HRB_MYSQL_CONNECTOR_LINK=$HRB_TMP_DIR/mysql-connector.jar
if [ ! -h $HRB_MYSQL_CONNECTOR_LINK ]; then
  ln -s ${HRB_LIB_DIR}/${HRB_MYSQL_CONNECTOR} $HRB_MYSQL_CONNECTOR_LINK
else
  echo "$(readlink $HRB_MYSQL_CONNECTOR_LINK)" | grep "$HRB_MYSQL_CONNECTOR" > /dev/null 2>&1
  test $? -ne 0 && {
    rm -f $HRB_MYSQL_CONNECTOR_LINK
    ln -s ${HRB_LIB_DIR}/${HRB_MYSQL_CONNECTOR} $HRB_MYSQL_CONNECTOR_LINK
  }
fi
export HADOOP_CLASSPATH=${HRB_MYSQL_CONNECTOR}
# https://issues.cloudera.org/browse/SQOOP-214
export HADOOP_OPTS="-Djava.security.egd=file:/dev/../dev/urandom"

# Use the same jdk as Hadoop's one.
export JAVA_HOME=/usr/java/default

# Utility functions
_datetime() { date +'%Y-%m-%d %H:%M:%S'; }
log_debug() { [ $HRB_LOG_LEVEL -le 0 ] && print_log "$(_datetime) [DEBUG]${progname:+" ${progname}:"} $@";  }
log_info()  { [ $HRB_LOG_LEVEL -le 1 ] && print_log "$(_datetime) [INFO]${progname:+" ${progname}:"} $@";  }
log_warn()  { [ $HRB_LOG_LEVEL -le 2 ] && print_log "$(_datetime) [WARN]${progname:+" ${progname}:"} $@";  }
log_error() { [ $HRB_LOG_LEVEL -le 3 ] && print_log "$(_datetime) [ERROR]${progname:+" ${progname}:"} $@"; }
print_log() { if [ -z $HRB_LOG_PATH ]; then echo "$@"; else echo "$@" >> $HRB_LOG_PATH; fi }
