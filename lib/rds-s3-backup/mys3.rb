=begin

= mys3.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Author(s)*::    Tamara Temple <tamara.temple@novu.com>
*Since*::        2013-02-26
*License*::      GPLv3
*Version*::      0.0.1

== Description

=end

module Rds::S3::Backup
  class MyS3Exception < RuntimeError ; end
  class MyS3

    def initialize(options)
      @options = options
    end

    # Lazy loaders
    def s3
      @s3 ||= get_storage(:aws_access_key_id => @options['aws_access_key_id'],
                          :aws_secret_access_key => @options['aws_secret_access_key'],
                          :region => @options['aws_s3_region'] ||= @options['aws_region'])
    end

    def s3_bucket
      @s3_bucket ||= get_bucket(@options['s3_bucket'])
    end

    def backup_bucket
      @backup_bucket ||= get_bucket(@options['backup_bucket'])
    end



    # Save the Real version of the Production Database
    #
    # == Input
    #
    # :file_path:: the path where the production database resides to save up to S3
    #
    def save_production(file_path)
      save(s3_bucket, file_path, :acl => 'private')
    end

    
    # Save the Cleaned (Obfuscated) Version of the Database
    #
    # == Input
    #
    # :file_path:: the path where the file resides to save up to S3
    #
    def save_clean(file_path)
      save(backup_bucket, file_path, :acl => 'authenticated-read')
    end


    # Remove older files from S3
    #
    # == Input
    #
    # o -- an options hash, expecting the following keys:
    #
    # :prefix:: the prefix to use with the s3 bucket
    # :keep::   the number of files to keep. Must keep at least one.
    def prune_files(o={})
      options = {
        :prefix => '',
        :keep => 1
      }.merge(o)
      
      raise MyS3Exception "Must keep at least one file. options[:keep] = #{options[:keep]}" if options[:keep] < 1 # must keep at least one, the last one!

      my_files = s3_bucket.files.all('prefix' => options[:prefix])
      return if my_files.nil?
      
      if my_files.count > options[:keep]
        my_files.
          sort {|x,y| x.last_modified <=> y.last_modified}.
          take(files_by_date.count - options[:keep]).
          each do |f|
          $logger.info "Deleting #{f.name}"
          f.destroy
        end
      end
    end


    # Make a connection to AWS S3 using Fog::Storage
    def get_storage(o={})
      options = {
        :aws_access_key_id => nil,
        :aws_secret_access_key => nil,
        :region => nil,
        :provider => 'AWS',
        :scheme => 'https'}.merge(o)
      
      begin
        storage = Fog::Storage.new(options)
      rescue Exception => e
        raise MyS3Exception.new "Error establishing storage connection: #{e.class}: #{e}"
      end
      
      $logger.debug "What is storage? #{storage.class}:#{storage.inspect}"
      raise MyS3Exception.new "In #{self.class}#get_storage: storage is nil!" if storage.nil?

      storage
    end


    # Retrieve a pointer to an AWS S3 Bucket
    def get_bucket(bucket)

      begin
        bucket = self.s3.directories.get(bucket)
      rescue Exception => e
        raise MyS3Exception.new "Error getting bucket #{bucket} in S3: #{e.class}: #{e}"
      end

      raise MyS3Exception.new "In #{self.class}#get_bucket: bucket is nil!" if bucket.nil?

      bucket
    end

    # Perform the actual save from a local file_path to AWS S3
    def save(bucket, file_path, o={})
      raise MyS3Exception.new "bucket is nil!!" if bucket.nil?
      options = {
        :key => File.join(@options['s3_prefix'], File.basename(file_path)),
        :body => File.open(file_path),
        :acl => 'authenticated-read',
        :encryption => 'AES256',
        :content_type => 'application/x-gzip'}.merge(o)
      
      tries = 0
      begin
        
        bucket.files.new(options).save

      rescue Exception => e
        if tries < 3
          $logger.info "Retrying S3 upload after #{tries} tries"
          tries += 1
          sleep tries * 60      # progressive back off
          retry
        else
          raise MyS3Exception.new "Could not save #{File.basename(file_path)} to S3 after 3 tries: #{e.class}: #{e}"
        end
      end

    end

    # nothing really to do here...    
    def destroy
    end


  end


end
