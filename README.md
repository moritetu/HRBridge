# Hadoop RDB Bridge

This is a simple wrapper for sqoop1.

## Required

* sqoop >= 1.4
* mysql >= 5.5

## Usage

### Database Setting

Update `conf/database.properties`

```
DatabaseHost=dbhost
DatabaseUser=user
DatabasePassword=password
```

### Get JDBC

Download mysql jdbc library into `lib` directory.

### Export

```
$ bin/hrbridge.sh hive-export --table sample --export-base-dir /user/hive/warehouse sample
```

#### Create Tables

```
$ bin/hrbridge.sh db-table --create --table-from conf/sync-tables.txt
```

#### Delete Tables

```
$ bin/hrbridge.sh db-table --drop --table-from conf/sync-tables.txt
```

### Environments Variables

```
DATABASE_HOST        host
DATABASE_DATABASE    database
DATABASE_USER        user
DATABASE_PASS        pass
HRB_ENVIRONMENT      Execution Context(dev or "")
HRB_LOG_LEVEL        Log Level(0:debug, 1:info, 2:warn, 3:error)
HRB_LOG_DIR          Log output directory
HRB_TMP_DIR          Temporary directory
HRB_LOG_PATH         Log file path
HRB_SQOOP_LOG_PATH   Log file path for sqoop
```

## See

* Sqoop Reference
  * http://sqoop.apache.org/docs/1.4.2/SqoopUserGuide.html#_exports_and_transactions
