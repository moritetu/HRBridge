#!/usr/bin/env bash
#
# hrbridge.sh helps data transport between hive and mysql.
#
set -u
here=$(cd -P -- "$(dirname -- ${BASH_SOURCE:-$0})" && pwd -P)
progname="$(basename -- ${BASH_SOURCE:-$0})"

# Loads setting
. ${here}/../conf/setting${HRB_ENVIRONMENT:+"-${HRB_ENVIRONMENT}"}.sh

DRY_RUN=0

usage() {
  cat<<EOF
usage: $(basename $0) command [<command parameters>]

command list:
    hive-export   Export tables in hive to mysql.
    db-table      Create or drop tables.

EOF
}

init_sqoop_options_file() {
  # Create sqoop-default-options.txt
  local SQOOP_DEFAULT_OPTIONS_FILE=${HRB_TMP_DIR}/sqoop-default-options${HRB_ENVIRONMENT:+"-${HRB_ENVIRONMENT}"}.txt

  if [ ! -e $SQOOP_DEFAULT_OPTIONS_FILE ] || [ ! -s $SQOOP_DEFAULT_OPTIONS_FILE ] ; then
    log_debug "make $SQOOP_DEFAULT_OPTIONS_FILE"
    cat ${HRB_CONF_DIR}/sqoop-default-options.txt.sample   |\
    sed -e "s/{DATABASE_HOST}/${DATABASE_HOST}/g"          |\
    sed -e "s/{DATABASE_DATABASE}/${DATABASE_DATABASE}/g"  |\
    sed -e "s/{DATABASE_USER}/${DATABASE_USER}/g"          |\
    sed -e "s/{DATABASE_PASS}/${DATABASE_PASS}/g"           \
      > $SQOOP_DEFAULT_OPTIONS_FILE
    chmod 600 $SQOOP_DEFAULT_OPTIONS_FILE
  fi
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage && exit
fi

SUB_COMMAND="$(echo $1 | sed 's/-/_/g')"
shift

# Loads sub commands.
SUB_COMMAND_LIST=""
for sub_command in $HRB_SUB_COMMAND_DIR/*.sh; do
  log_debug "include $sub_command"
  . $sub_command
done


# Init sqoop-options-file
init_sqoop_options_file

# Detects called function.
CALL_FUNC=""
for com in $SUB_COMMAND_LIST; do
  if [ "$com" = "$SUB_COMMAND" ]; then
    log_debug "found sub command: $com"
    CALL_FUNC=$com
    break
  fi
done

if [ "$CALL_FUNC" = "" ]; then
  log_error "invalid command: '$SUB_COMMAND'"
  exit 1
else
  log_info "call function $CALL_FUNC"
  $CALL_FUNC "$@"
fi
