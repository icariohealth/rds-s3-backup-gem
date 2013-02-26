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

    def initialise(options)
      @options = options

      @s3 = get_storage(:aws_access_key_id => @options.aws_access_key_id,
                        :aws_secret_access_key => @options.aws_secret_access_key,
                        :region => @options.aws_s3_region ||= @options.aws_region)
    end

    def get_storage(o={})
      options = {
        :aws_access_key_id => nil,
        :aws_secret_access_key => nil,
        :region => nil,
        :provider => 'AWS',
        :scheme => 'https'}.merge(o)
      
      begin
        Fog::Storage.new(options)
      rescue Exception => e
        raise MyS3Exception.new "Error establishing storage connection: #{e.class}: #{e}"
      end
      
    end

    def get_bucket(bucket)

      begin
        @s3.directories.get(bucket)
      rescue Exception => e
        raise MyS3Exception.new "Error getting bucket #{bucket} in S3: #{e.class}: #{e}"
      end

    end

    def save_production(file_path)
      save(s3_bucket, file_path, :acl => 'private')
    end

    def save_clean(file_path)
      save(backup_bucket, file_path, :acl => 'authenticated-read')
    end



    def save(bucket, file_path, o={})
      options = {
        :key => File.join(@options.s3_prefix, File.basename(file_path)),
        :body => File.open(file_path),
        :acl => 'authenticated-read',
        :encryption => 'AES256',
        :content_type => 'application/x-gzip'}.merge(o)
      
      tries = 0
      begin
        
        bucket.files.new(options).save

      rescue Exception => e
        if tries < 3
          @logger.info "Retrying S3 upload after #{tries} tries"
          tries += 1
          retry
        else
          raise MyS3Exception.new "Could not save #{File.basename(file_path)} to S3 after 3 tries: #{e.class}: #{e}"
        end
      end

    end


    def s3_bucket
      @s3_bucket ||= get_bucket(@options.s3_bucket)
    end

    def backup_bucket
      @backup_bucket ||= get_bucket(@options.backup_bucket)
    end


    def prune_files(o={})
      options = {
        :prefix => '',
        :keep => 1
      }.merge(o)
      
      return if options[:keep] < 1 # must keep at least one, the last one!

      my_files = s3_bucket.files.all('prefix' => options[:prefix])
      return if my_files.nil?
      
      if my_files.count > options[:keep]
        my_files.
          sort {|x,y| x.last_modified <=> y.last_modified}.
          take(files_by_date.count - options[:keep]).
          each do |f|
          logger.info "Deleting #{f.name}"
          f.destroy
        end
      end
    end

    def destroy
      # nothing really to do here...
    end


  end


end
