#
# If use, please pass this as the option file when execute 'hive-export' command.
#
# The line which starts from '#' is comment.
#
# refrence: http://sqoop.apache.org/docs/1.4.2/SqoopUserGuide.html
#

# mapper num 1
#SQOOP_OPTIONS="-m 1 $SQOOP_OPTIONS"

# Field terminator
SQOOP_OPTIONS="--input-fields-terminated-by \001 $SQOOP_OPTIONS"

# Line terminator-
SQOOP_OPTIONS="--input-lines-terminated-by \n $SQOOP_OPTIONS"

# Output directory for compiled objects
SQOOP_OPTIONS="--bindir ${HRB_TMP_DIR}/export/${table}/bin $SQOOP_OPTIONS"

# Output directory for generated code
SQOOP_OPTIONS="--outdir ${HRB_TMP_DIR}/export/${table} $SQOOP_OPTIONS"

# Input null string for string
SQOOP_OPTIONS="--input-null-string \\\\N $SQOOP_OPTIONS"

# Input null string for non string
SQOOP_OPTIONS="--input-null-non-string \\\\N $SQOOP_OPTIONS"

# Output directory for compiled and archived objects.
jarfile="${HRB_TMP_DIR}/export/${table}/bin/${table}.jar"
if [ -e "$jarfile" ]; then
  log_info "Found a jar file: $jarfile"
  SQOOP_OPTIONS="--jar-file ${jarfile} $SQOOP_OPTIONS"
  # When combined with '--jar-file', required.
  SQOOP_OPTIONS="--class-name ${table} $SQOOP_OPTIONS"
fi
