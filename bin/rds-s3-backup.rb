#!/usr/bin/env ruby
=begin

= rds-s3-backup-new.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Since*::        2013-02-25

== Description

Perform the nightly backup from production to S3, creating an obfuscated backup along the way

=end

require 'rubygems'
require 'thor'

require 'rds-s3-backup'

require 'fog'

require 'logger'
require 'dogapi'

class RdsS3Backup < Thor

  desc "s3_dump", "Runs a mysqldump from a restored snapshot of the specified RDS instance, and uploads the dump to S3"
  method_option :rds_instance_id
  method_option :s3_bucket
  method_option :backup_bucket
  method_option :s3_prefix
  method_option :aws_access_key_id
  method_option :aws_secret_access_key
  method_option :mysql_database
  method_option :mysql_username
  method_option :mysql_password
  method_option :obfuscate_sql, :desc => 'Obfuscation Stored Procedure source'
  method_option :dump_ttl, :desc => "Number of old dumps to keep."
  method_option :dump_directory => "Where to store the temporary sql dump file."
  method_option :config_file, :desc => "YAML file of defaults for any option. Options given during execution override these."
  method_option :aws_region, :desc => "Region of your RDS server (and S3 storage, unless aws-s3-region is specified)."
  method_option :aws_s3_region, :desc => "Region to store your S3 dumpfiles, if different from the RDS region"
  method_option :db_subnet_group_name, :desc => "VPC RDS DB subnet"
  method_option :db_instance_type, :desc => "DB Instance type"
  method_option :instance_id, :desc => "Instance ID to create/mount EBS to"
  method_option :log_level, :desc => "Set the level of verbosity. (debug|normal|warn|error|fatal)"

  def s3_dump
    thor_defaults = {
      'backup_bucket' => 'novu-backups',
      's3_prefix' => 'db_dumps',
      'obfuscate_sql' => '/usr/local/etc/obfuscate.sql',
      'dump_directory' => '/mnt/secure',
      'dump_ttl' => 0,
      'aws_region' => 'us-east-1',
      'aws_s3_region' => 'us-west-2',
      'db_instance_type' => 'db.m1.small',
      'log_level' => 'info'
    }


    Rds::S3::Backup.run(options,thor_defaults)
  end

end

RdsS3Backup.start
