#!/usr/bin/env bash
#
# Export from tables in hive to mysql.
#
THIS_COMMAND="hive_export"
SUB_COMMAND_LIST="${SUB_COMMAND_LIST}${THIS_COMMAND} "

hive_export_help() {
  cat<<EOF
usage: $(basename $0) hive_export [options] [<table>...]

options:
    -h, --help
        Show usage.

    --dry-run
        Exec on test mode.

    --table-from <table_list_file>
        Read tables from the file.

    --table-suffix <suffix>
        The suffix of the table that is newly created on the target database. By default, exported table name.

    --sqoop-options-file <option_file>
        Read options from the file. By default, 'conf/sqoop-default-options.txt' is used.
        This option is expanded as 'sqoop --options-file <option_file>'.

    --sqoop-options-per-table <option_file>
        Read the file and passes options to sqoop. This file is evaluated in the shell script context.
        For example, you use the following file:

        # your extra sqoop option
        SQOOP_OPTIONS="--export-dir /user/hive/warehouse/sample.db \$SQOOP_OPTIONS"
        SQOOP_OPTIONS="-m 1 \$SQOOP_OPTIONS"

    --sqoop-options <options>
        The options which passed to sqoop.

    --export-base-dir <export_base_dir>
        Passed to sqoop as sqoop option '--export-dir <export_base_dir>/<table>'. By default, 'conf/setting.sh' is used.

    --hive-database <hive_database>
        The database to export from hive. By default, 'conf/setting.sh' is used.

example:

    * Exports the tables written in sync-tables.txt.
        $SUB_COMMAND --table-from sync-tables.txt

    * Exports the 'sample' table.
        $SUB_COMMAND sample

EOF
}

# Exports tables in hive to mysql.
hive_export() {
  local SQOOP_EXPORT="sqoop export"
  local SYNC_TABLES=${SYNC_TABLES:-""}
  local SQOOP_OPTIONS_FILE=${SQOOP_OPTIONS_FILE:-"${HRB_TMP_DIR}/sqoop-default-options${HRB_ENVIRONMENT:+"-${HRB_ENVIRONMENT}"}.txt"}
  local SQOOP_OPTIONS=${SQOOP_OPTIONS:-""}
  local SQOOP_OPTIONS_PER_TABLE=${SQOOP_OPTIONS_PER_TABLE:-""}
  local HIVE_DATABASE_DIR=${HIVE_DATABASE_DIR:-""}  
  local HIVE_EXPORT_DATABASE=${HIVE_EXPORT_DATABASE:-""}
  local EXPORT_BASE_DIR=${EXPORT_BASE_DIR:-""}
  local TABLE_SUFFIX=""

  DRY_RUN=0

  [ $# -eq 0 ] && hive_export_help && exit

  # Parse options.
  while [ $# -gt 0 ]; do
    case $1 in
      --table-from)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" && exit 1
        SYNC_TABLES="$(sed -e /^#/d $1)"
        ;;
      --table-suffix)
        shift
        TABLE_SUFFIX="$1"
        ;;
      --sqoop-options-file)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" && exit 1
        SQOOP_OPTIONS_FILE="$1"
        ;;
      --sqoop-options-per-table)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" >&2 && exit 1
        SQOOP_OPTIONS_PER_TABLE="$1"
        ;;
      --sqoop-options)
        shift
        SQOOP_OPTIONS="$1 $SQOOP_OPTIONS"
        ;;
      --export-base-dir)
        shift
        EXPORT_BASE_DIR="$1"
        ;;
      --hive-database)
        shift
        HIVE_EXPORT_DATABASE="$1"
        ;;
      -h|--help)
        hive_export_help && exit
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      -*)
        log_error "$1: invalid option"
        exit 1
        ;;
      *)
        break
        ;;
    esac
    shift
  done

  if [ "$SQOOP_OPTIONS_FILE" != "" ]; then
    log_debug "use '--options-file $SQOOP_OPTIONS_FILE'"
    SQOOP_OPTIONS="--options-file $SQOOP_OPTIONS_FILE $SQOOP_OPTIONS"
  fi
  
  if [ $# -gt 0 ]; then
    SYNC_TABLES="${SYNC_TABLES} $@"
  fi

  if [ "$EXPORT_BASE_DIR" = "" ]; then
    EXPORT_BASE_DIR=${HIVE_DATABASE_DIR}/${HIVE_EXPORT_DATABASE}
    log_debug "export_base_dir is $EXPORT_BASE_DIR"
  fi

  #
  # Load tables from a file.
  #
  res=0
  if [ "$SYNC_TABLES" != "" ]; then
    SQOOP_FIX_OPTIONS=$SQOOP_OPTIONS
    for table in $SYNC_TABLES; do
      log_debug "export $table"
      new_table="$table${TABLE_SUFFIX}"
      SQOOP_OPTIONS=""
      [ "$SQOOP_OPTIONS_PER_TABLE" != "" ] && . $SQOOP_OPTIONS_PER_TABLE
      run="$SQOOP_EXPORT $SQOOP_FIX_OPTIONS $SQOOP_OPTIONS --table $new_table --export-dir ${EXPORT_BASE_DIR}/${table}"
      if [ $DRY_RUN -eq 1 ]; then
        echo "$run"
      else
        log_info "=> export table $table from hive"
        if [ -z $HRB_SQOOP_LOG_PATH ]; then
          $run
        else
          $run >> $HRB_SQOOP_LOG_PATH 2>&1
        fi
        _res=$?
        if [ $_res -ne 0 ]; then
            res=$_res
            log_error "failed to export: status=$res $run"
        fi
      fi
    done
  else
    log_warn "SYNC_TABLES is empty."
    log_warn "Please pass '--table-from' option or <table> with arguments."
    exit 1
  fi
  return $res
}
