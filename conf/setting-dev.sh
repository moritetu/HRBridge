#
# HRB basic setting.
#

# Paths
HRB_HOME=${HRB_HOME:-"$(dirname $(cd -P -- "$(dirname -- ${BASH_SOURCE:-$0})" && pwd -P))"}

. ${HRB_HOME}/conf/setting.sh

# debug: 0, info: 1, warn:2, error:3
HRB_LOG_LEVEL=0
# If the path is empty, output to stdout. Otherwise file.
HRB_LOG_PATH=${HRB_LOG_PATH:-""}
