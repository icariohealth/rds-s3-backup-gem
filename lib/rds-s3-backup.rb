require 'yaml'
require 'logger'
require "rds-s3-backup/version"
require "rds-s3-backup/datadog"
require "rds-s3-backup/myrds"
require "rds-s3-backup/mys3"
require "rds-s3-backup/mysqlcmds"
require 'debugger'

module Rds
  module S3
    module Backup
      
      def process_options(thor_options,thor_defaults)

        options = thor_defaults

        if thor_options[:config_file] && File.exists?(thor_options[:config_file])
          begin
            options = options.merge(YAML.load(File.read(thor_options[:config_file])))
          rescue Exception => e
            raise "Unable to read and parse #{thor_options[:config_file]}: #{e.class}: #{e}"
          end
        end

        options.merge!(thor_options)

        # Check for required options
        missing_options = %w{rds_instance_id s3_bucket aws_access_key_id aws_secret_access_key mysql_database mysql_username mysql_password}.reduce([]) {|a, o| a << o unless options.has_key?(o); a}

        raise "Missing required options #{missing_options.inspect} in either configuration or command line" if missing_options.count > 0
        
        options['timestamp'] = Time.new.strftime('%Y-%m-%d-%H-%M-%S-%Z') #  => "2013-02-25-19-28-55-CST" 

        options
      end

      def run(thor_options,thor_defaults)

        @options = process_options(thor_options,thor_defaults)
        $logger = Logger.new(STDOUT)
        $logger.level = set_logger_level(@options["log_level"])

        $dogger = DataDog.new(@options['data_dog_api_key'])

        "Starting RDS-S3-Backup at #{@options['timestamp']}".tap do |t|
          $logger.info t
          $dogger.send t
        end


        begin
          debugger              # TODO: REMOVE FOR RELEASE!!!!

          $logger.info "Creating RDS and S3 Connections"
          rds = MyRDS.new(@options)
          s3 = MyS3.new(@options)

          $logger.info "Restoring Database"
          rds.restore_db()

          $logger.info "Dumping and saving original database contents"
          real_data_file = "#{rds.server.id}-mysqldump-#{@options['timestamp']}.sql.gz"
          s3.save_production(rds.dump(real_data_file))

          if @options['dump_ttl'] > 0
            $logger.info "Pruning old dumps"
            s3.prune_files(:prefix => "#{rds.server.id}-mysqldump-",
                           :keep => @options['dump_ttl'])
          end

          $logger.info "Obfuscating database"
          rds.obfuscate()

          $logger.info "Dumping and saving obfuscated database contents"
          clean_data_file = "clean-mysqldump.sql.gz" 
          s3.save_clean(rds.dump(clean_data_file))
          
        rescue Exception => e
          msg = "ERROR in #{File.basename(__FILE__)}: #{e.class}: #{e}\n"
          msg << e.backtrace.join("\n")
          $logger.error msg
          $dogger.send msg unless e.is_a?(DataDogException) # don't make a loop!
          raise e
        ensure
          cleanup(rds, s3, [ real_data_file, clean_data_file ])
        end
        
        "RDS-S3-Backup Completed Successfully".tap do |t|
          $logger.info t
          $dogger.send t, :alert_type => 'Info', :priority => 'low'
        end

        0                           # exit code 0


      end

      def cleanup(rds, s3, unlink_files=[])
        rds.destroy() unless rds.nil?
        s3.destroy() unless s3.nil?
        
        unlink_files = [ unlink_files ] unless unlink_files.is_a?(Array)
        unlink_files = unlink_files.flatten
        unlink_files.each {|f| File.unlink(f) if !f.nil? && File.exists?(f) }

      end

      def set_logger_level(ll)
        debugger
        case ll.downcase
        when 'debug' ; Logger::DEBUG
        when 'info' ; Logger::INFO
        when 'warn' ; Logger::WARN
        when 'error' ; Logger::ERROR
        when 'fatal' ; Logger::FATAL
        else
          Logger::INFO
        end
      end

      module_function :process_options, :run, :cleanup, :set_logger_level

    end
  end
end
