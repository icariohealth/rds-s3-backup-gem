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
  method_option :backup_bucket, :default => 'novu-backups'
  method_option :s3_prefix, :default => 'db_dumps'
  method_option :aws_access_key_id
  method_option :aws_secret_access_key
  method_option :mysql_database
  method_option :mysql_username
  method_option :mysql_password
  method_option :obfuscate_sql, :default => '/usr/local/etc/obfuscate.sql', :desc => 'Obfuscation Stored Procedure source'
  method_option :dump_ttl, :default => 0, :desc => "Number of old dumps to keep."
  method_option :dump_directory, :default => '/mnt/secure', :desc => "Where to store the temporary sql dump file."
  method_option :config_file, :desc => "YAML file of defaults for any option. Options given during execution override these."
  method_option :aws_region, :default => "us-east-1", :desc => "Region of your RDS server (and S3 storage, unless aws-s3-region is specified)."
  method_option :aws_s3_region, :default => "us-west-2", :desc => "Region to store your S3 dumpfiles, if different from the RDS region"
  method_option :db_subnet_group_name, :desc => "VPC RDS DB subnet"
  method_option :db_instance_type, :default => "db.m1.small", :desc => "DB Instance type"
  method_option :instance_id, :desc => "Instance ID to create/mount EBS to"
  method_option :log_level, :default => 0, :desc => "Set the level of verbosity. -1=debug, 0=normal, 1=warnings, 2=errors, 3=fatal"
  method_option :quiet, :default => false, :desc => "Only report warnings and above (i.e., log_level 1)"
  method_option :verbose, :default => true, :desc => "Report info and above (i.e. log_level 0)"

  def s3_dump
    Rds::S3::Backup.run(options)
  end

end

RdsS3Backup.start
