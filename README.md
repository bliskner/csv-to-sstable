

# CSV to Cassandra SSTable

Converts a CSV file into SSTables that can be bulkloaded into a Cassandra cluster using the sstableloader

## changelog

- [2017-01-23] 
  - added support for reading files from stdin
  - added rudimental tests

## Installation

Make sure that maven is installed on your system. Then to build the jar file, run:

    $ ./build

## Prerequisites

csv-to-sstable.jar needs a few things in order to run:

- a properties file
- a keyspace definition
- a table definition
- command line arguments
- csv file as input
- space on your disk to store the resulting sstable

## The properties file

```
cat > your/properties << 'EOF'
keyspace = csv2sstable_test
keyspace_definition_file = your/keyspace.cql
table_definition_file = your/table.cql
# csv_preferences as a json encoded string
csv_preferences = {"col_sep": ",", "quote_char": "\\""}
csv_header = timestamp_field,text_field,float_field,int_field,bigint_field,boolean_field
# 1day
ttl = 86400
timestamp = 1484921269
EOF
```

Some properties from the property file can be left empty, but should not be entirely removed.
You can either have the header definition within the properties or within the fist line of the file (never both).

## The keyspace definition

```
cat > your/keyspace.cql << 'EOF'
CREATE KEYSPACE csv2sstable_test WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': '3', 'dc2': '1'}  AND durable_writes = true;
EOF
```

## The table definition and supported column types

```
cat > ${tmpdir}/table.cql << 'EOF'
CREATE TABLE my_keyspace.my_table (
    my_column1 timestamp,
    my_column2 text,
    my_column3 float,
    my_column4 int,
    my_column5 bigint,
    my_column6 boolean,
    PRIMARY KEY ((my_column2, my_column1), my_column3)
);
EOF
```

## Command line arguments

    $ java -Xmx1g -jar ./csv-to-sstable.jar path/to/your/properties csv/input/path sstable/output/path

csv-to-sstable is able to also read your file from stdin,
making things like this possible:

    $ lz4 -d /path/to/your/csv.lz4 | java -Xmx1g -jar ./csv-to-sstable.jar ./your.properties - sstable/output/path

## How to get the sstables loaded into cassandra

After the SSTables have been generated, you can bulkload them into Cassandra by using sstableloader. Assuming that you have a running local Cassandra cluster installed in ~/cassandra, run:

    $ ~/cassandra/bin/sstableloader -d localhost Users/home/sstables/my_keyspace/my_table

## What should i do if i encounter problems and things don't work?

you may want to check the ./test.sh script,
if this does not help and you can not fix it (see below),
please let me know
https://github.com/bliskner/csv-to-sstable/issues

## Contributing

(changed forking path because it seems the the original project is dead)

1. Fork it ( https://github.com/bliskner/csv-to-sstable/fork )
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

##License

Copyright 2015 SPB TV AG

Licensed under the Apache License, Version 2.0 (the ["License"](LICENSE)); you may not use this file except in compliance with the License.

You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

See the License for the specific language governing permissions and limitations under the License.