#!/usr/bin/env bash
#
# Export from tables in hive to mysql.
#
THIS_COMMAND="db_table"
SUB_COMMAND_LIST="${SUB_COMMAND_LIST}${THIS_COMMAND} "

db_table_help() {
  cat<<EOF
usage: $(basename $0) db_table <operation> [options] [<table>...]

operation:
    --create
        Create table.

    --drop
        Drop table.

    --drop-create
        Drop and create table.

    --delete
        Delete from table. Use 'TRUNCATE TABLE <table>'.

    --swap
        Swap the old table for the new table.

options:
    -h, --help
        Show usage.

    --dry-run
        Exec on test mode.

    --table-from <table_list_file>
        Read table list from a file.

    --setting <file>
        Use the setting with the assigned file. The following are the details.
          DATABASE_HOST       The host name
          DATABASE_DATABASE   The database
          DATABASE_USER       The database user
          DATABASE_PASS       The pass of the user.
                              Do not input this value in command line, because it is displayed in command history.

example:

    * Create tables.
        db-table --create --table-from conf/sync-tables.txt

    * Drop tables.
        db-table --drop --table-from conf/sync-tables.txt

    * Delete tables.
        db-table --delete --table-from conf/sync-tables.txt

    * Swap tables
        db-table --swap <old_table> <new_table>

EOF
}

# Operation db table.
db_table() {
  [ $# -eq 0 ] && db_table_help && exit

  local OPERATION=""
  local MYSQL="mysql"
  local TABLES=${TABLES:-""}

  # Parse options.
  while [ $# -gt 0 ]; do
    case $1 in
      -h|--help)
        db_table_help && exit
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --table-from)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" && exit 1
        TABLES="$(sed -e /^#/d $1)"
        ;;
      --table-from)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" && exit 1
        TABLES="$(sed -e /^#/d $1)"
        ;;
      --create)       OPERATION="create"      ;;
      --drop)         OPERATION="drop"        ;;
      --delete)       OPERATION="delete"      ;;
      --drop-create)  OPERATION="drop_create" ;;
      --swap)         OPERATION="swap"        ;;
      --setting)
        shift
        [ ! -e "$1" ] && log_error "The file does not exist: $1" && exit 1
        . "$1"
        ;;
      -*)
        log_error "$1: Invalid option"
        exit 1
        ;;
      *)
        break
        ;;
    esac
    shift
  done

  [ ! -z "$DATABASE_PASS" ] &&  {
    [ $DRY_RUN -eq 1 ] && DATABASE_PASS="xxxxx"
    MYSQL="$MYSQL --defaults-extra-file=<(printf '[client]\npassword=%s\n' "$DATABASE_PASS")"
  }
  [ ! -z "$DATABASE_HOST" ] &&  MYSQL="$MYSQL --host $DATABASE_HOST"
  [ ! -z "$DATABASE_USER" ] &&  MYSQL="$MYSQL --user $DATABASE_USER"
  [ ! -z "$DATABASE_DATABASE" ] &&  MYSQL="$MYSQL $DATABASE_DATABASE"

  if [ "$OPERATION" = "" ]; then
    log_warn "required <operation> option."
    exit 1
  fi

  if [ $# -gt 0 ]; then
    TABLES="${TABLES} $@"
  fi

  #
  # Load tables from a file.
  #
  if [ "$TABLES" != "" ]; then
    CALL_FUNC="db_table_${OPERATION}"
    log_debug "call function $CALL_FUNC"
    $CALL_FUNC "$MYSQL" "$TABLES"
  else
    log_warn "TABLES is empty."
    log_warn "Please pass '--table-from' option or <table> with arguments."
    exit 1
  fi
}

# Create table
#
# $1: mysql command
# $2: table list
db_table_create() {
  local MYSQL="$1"
  local TABLES="$2"

  res=0
  for table in $TABLES; do
    sql_file="${HRB_DB_DIR}/create_${table}.sql"
    log_debug "exec $sql_file"
    if [ $DRY_RUN -eq 1 ]; then
      echo "$MYSQL < $sql_file"
    else
      log_info "=> create table $table"
      eval "$MYSQL < ${sql_file}"; _res=$?
      if [ $_res -eq 0 ]; then
        log_info "ok"
      else
        res=$_res
        log_error "fail: status=$res"
      fi
    fi
  done
  return $res
}

# Drop table
# 
# $1: mysql command
# $2: table list
db_table_drop() {
  local MYSQL="$1"
  local TABLES="$2"

  res=0
  for table in $TABLES; do
    sql="'DROP TABLE IF EXISTS ${table};'"
    if [ $DRY_RUN -eq 1 ]; then
      echo "$MYSQL -e $sql"
    else
      log_info "=> drop table $table"
      eval "$MYSQL -e $sql"; _res=$?
      if [ $_res -eq 0 ]; then
        log_info "ok"
      else
        res=$_res
        log_error "fail: status=$res"
      fi
    fi
  done
  return $res
}

# Drop and create table
#
# $1: mysql command
# $2: table list
db_table_drop_create() {
  db_table_drop "$@"
  db_table_create "$@"
}

# Delete(truncate) from table
#
# $1: mysql command
# $2: table list
db_table_delete() {
  local MYSQL="$1"
  local TABLES="$2"

  res=0
  for table in $TABLES; do
    sql="'SET autocommit=true; TRUNCATE TABLE ${table};'"
    log_debug "exec: $sql"
    if [ $DRY_RUN -eq 1 ]; then
      echo "$MYSQL -e $sql"
    else
      log_info "=> truncate table $table"
      eval "$MYSQL -e $sql"; _res=$?
      if [ $_res -eq 0 ]; then
        log_info "ok"
      else
        res=$_res
        log_error "fail: status=$res"
      fi
    fi
  done
  return $res
}


# Swap tables
#
# $1: mysql command
# $2: old table
# $3: new table
db_table_swap() {
  local MYSQL="$1"
  local TABLES=($2)
  if test "${#TABLES[@]}" -le 1; then
    log_error "swap <old_table> <new_table>"
    log_error "exit"
    return 1
  fi

  local OLD_TABLE=${TABLES[0]}
  local NEW_TABLE=${TABLES[1]}

  res=0
  sql="'RENAME TABLE ${OLD_TABLE} TO ${OLD_TABLE}_trashed, ${NEW_TABLE} TO ${OLD_TABLE};'"
  log_debug "exec: $sql"
  if [ $DRY_RUN -eq 1 ]; then
    echo "$MYSQL -e $sql"
    db_table_drop "$MYSQL" "${OLD_TABLE}_trashed"
  else
    log_info "=> swap $OLD_TABLE for $NEW_TABLE"
    eval "$MYSQL -e $sql"; _res=$?
    if [ $_res -eq 0 ]; then
      log_info "ok, drop ${OLD_TABLE}_trashed"
      db_table_drop "$MYSQL" "${OLD_TABLE}_trashed"
      res=$?
    else
      res=$_res
      log_error "fail: status=$res"
    fi
  fi
  return $res
}
