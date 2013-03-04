# Rds::S3::Backup

The rds-s3-backup gem is a thor script that take a backup of an AWS RDS server and saves the mysqldump to an S3 bucket.
Then it runs an obfuscation SQL script and saves the mysqldump to another S3 bucket.

## Installation

This gem is intended for use in a Chef recipe, and can be installed in your cookbook's recipe default recipe file as:

    gem-package 'rds-s3-backup'
	  action :install
	end

It can be installed stand-alone as well via the usual:

    gem install rds-s3-backup

## Usage

    rds-s3-backup.rb s3-dump [options]
	
## Options:
*  `--rds-instance-id=RDS_INSTANCE_ID`
*  `--s3-bucket=S3_BUCKET`
*  `--backup-bucket=BACKUP_BUCKET`
*  `--s3-prefix=S3_PREFIX`
*  `--aws-access-key-id=AWS_ACCESS_KEY_ID`
*  `--aws-secret-access-key=AWS_SECRET_ACCESS_KEY`
*  `--mysql-database=MYSQL_DATABASE`
*  `--mysql-username=MYSQL_USERNAME`
*  `--mysql-password=MYSQL_PASSWORD`
*  `--fog-timeout=FOG_TIMEOUT`
*  `--obfuscate-sql=OBFUSCATE_SQL`
*  `--dump-ttl=DUMP_TTL`
*  `--dump-directory=DUMP_DIRECTORY`
*  `--config-file=CONFIG_FILE`
*  `--aws-region=AWS_REGION`
*  `--aws-s3-region=AWS_S3_REGION`
*  `--db-subnet-group-name=DB_SUBNET_GROUP_NAME`
*  `--db-instance-type=DB_INSTANCE_TYPE`
*  `--instance-id=INSTANCE_ID`
*  `--log-level=LOG_LEVEL`

## Configuration File

The configuration file, specified by `--config-file` parameter is a YAML file with tags consisting of the option names without leading dashs, and internal dashes converted to underscores. Thus:

~~~~~~
rds_instance_id: "RDS Instance ID"
db_subnet_group_name: "Subnet Group Name"
s3_bucket: "S3 bucket"
aws_access_key_id: "AWS KEY"
aws_secret_access_key: "AWS SECRET KEY"
mysql_database: "dbname"
mysql_username: "user"
mysql_password: "password"
dump_ttl: 0
data_dog_api_key: "DDOG API"
obfuscate_sql: "path/to/obfuscator/script.sql"
dump_directory: "path/to/local/directory/to/hold/dumps"
fog_timeout: 30*60
~~~~~~

and so on.

Configuration file setting will override programmed defaults, and command line options will override configuration file settings.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
