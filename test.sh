#!/bin/bash

tmpdir=./tmp

csv_to_sstable_jar=./csv-to-sstable.jar

keyspace="csv2sstable_test"
table="table"

csvfile=${tmpdir}/data.csv
ttl=20000000
timestamp=$(date +%s)

####################################################
## setting up all files and folders for the tests
####################################################

if [ ! -d ${tmpdir} ]; then
  mkdir ${tmpdir}
fi

cat > ${tmpdir}/keyspace.cql << 'EOF'
CREATE KEYSPACE csv2sstable_test WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': '3', 'dc2': '1'}  AND durable_writes = true;
EOF

cat > ${tmpdir}/table.cql << 'EOF'
CREATE TABLE csv2sstable_test.testtable (
    timestamp_field timestamp,
    text_field text,
    float_field float,
    int_field int,
    bigint_field bigint,
    boolean_field boolean,
    PRIMARY KEY ((timestamp_field, text_field), int_field)
);
EOF

cat > ${tmpdir}/data.csv << 'EOF'
"1484916594","some text","3.2","2147483647","9223372036854775807","1"
"1484916595","text2","3.6","-2147483647","-9223372036854775807","0"
"1484916596","third text","3.2","2147483647","9223372036854775807","1"
EOF

cat > ${tmpdir}/test.properties << 'EOF'
keyspace = csv2sstable_test
keyspace_definition_file = tmp/keyspace.cql
table_definition_file = tmp/table.cql
# csv_preferences as a json encoded string
csv_preferences = {"col_sep": ",", "quote_char": "\\""}
csv_header = timestamp_field,text_field,float_field,int_field,bigint_field,boolean_field
# 1day
ttl = 86400
timestamp = 1484921269
EOF

####################################################
## reading csv from stdin
####################################################

echo -n "reading from stdin ..."
cat ${tmpdir}/data.csv | java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties - ${csvfile}.sstable &>/dev/null
if [ $? -eq 0 ]; then
  echo " [success]"
else
  echo " [failure]"
  echo "please check the output when running the following command:"
  echo "cat ${tmpdir}/data.csv | java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties - ${csvfile}.sstable"
fi

####################################################
## reading csv from file
####################################################

echo -n "reading from file ..."
java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties ${csvfile} ${csvfile}.sstable &>/dev/null
if [ $? -eq 0 ]; then
  echo " [success]"
else
  echo " [failure]"
  echo "please check the output when running the following command:"
  echo "java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties ${csvfile} ${csvfile}.sstable"
fi

####################################################
## reading from stdin with headers in file
####################################################

cat > ${tmpdir}/data.csv << 'EOF'
"timestamp_field","text_field","float_field","int_field","bigint_field","boolean_field"
"1484916594","some text","3.2","2147483647","9223372036854775807","1"
"1484916595","text2","3.6","-2147483647","-9223372036854775807","0"
"1484916596","third text","3.2","2147483647","9223372036854775807","1"
EOF

cat > ${tmpdir}/test.properties << 'EOF'
keyspace = csv2sstable_test
keyspace_definition_file = tmp/keyspace.cql
table_definition_file = tmp/table.cql
# csv_preferences as a json encoded string
csv_preferences = {"col_sep": ",", "quote_char": "\\""}
csv_header = 
# 1day
ttl = 86400
timestamp = 1484921269
EOF

echo -n "reading from stdin (header in 1st line)..."
cat ${tmpdir}/data.csv | java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties - ${csvfile}.sstable &>/dev/null
if [ $? -eq 0 ]; then
  echo " [success]"
else
  echo " [failure]"
  echo "please check the output when running the following command:"
  echo "cat ${tmpdir}/data.csv | java -Xmx1g -jar ${csv_to_sstable_jar} ${tmpdir}/test.properties - ${csvfile}.sstable"
fi

