require 'yaml'
require 'logger'
require "rds-s3-backup/version"
require "rds-s3-backup/datadog"
require "rds-s3-backup/myrds"
require "rds-s3-backup/mys3"
require "rds-s3-backup/mysqlcmds"

module Rds
  module S3
    module Backup
      
      def process_options(thor_options)


        STDERR.puts "DEBUG: thor_options: #{thor_options.inspect}"


        if thor_options[:config_file] && File.exists?(thor_options[:config_file])
          begin
            options = YAML.load(File.read(thor_options[:config_file])).merge(thor_options) # let command line values overwrite config file values
          rescue Exception => e
            raise "Unable to read and parse #{thor_options[:config_file]}: #{e.class}: #{e}"
          end
        else
          options = thor_options
        end

        STDERR.puts "DEBUG: options: #{options.inspect}"


        # Check for required options
        missing_options = %w{rds_instance_id s3_bucket aws_access_key_id aws_secret_access_key mysql_database mysql_username mysql_password}.reduce([]) {|a, o| a << o unless options.has_key?(o); a}

        raise "Missing required options #{missing_options.inspect} in either configuration or command line" if missing_options.count > 0
        
        options['timestamp'] = Time.new.strftime('%Y-%m-%d-%H-%M-%S-%Z') #  => "2013-02-25-19-28-55-CST" 

        options
      end

      def load(filename)
        return {} unless File.exists?(filename)
      end



      def run(options)

        @options = process_options(options)
        @logger = Logger.new(STDOUT)
        @logger.level = set_logger_level(@options['log_level'], @options['quiet'], @options['verbose'])

        @dogger = DataDog.new(@options['data_dog_api_key'])

        "Starting RDS-S3-Backup at #{@options[:timestamp]}".tap do |t|
          @logger.info t
          @dogger.send t
        end


        begin

          @logger.info "Creating RDS and S3 Connections"
          rds = MyRDS.new(@options)
          s3 = MyS3.new(@options)

          @logger.info "Restoring Database"
          rds.restore_db()

          @logger.info "Dumping and saving original database contents"
          real_data_file = "#{rds.server.id}-mysqldump-#{@options[:timestamp]}.sql.gz"
          s3.save_production(rds.dump(real_data_file))

          if @options['dump_ttl'] > 0
            @logger.info "Pruning old dumps"
            s3.prune_files(:prefix => "#{rds.server.id}-mysqldump-",
                           :keep => @options['dump_ttl'])
          end

          @logger.info "Obfuscating database"
          rds.obfuscate()

          @logger.info "Dumping and saving obfuscated database contents"
          clean_data_file = "clean-mysqldump.sql.gz" 
          s3.save_clean(rds.dump(clean_data_file))
          
        rescue Exception => e
          msg = "ERROR in #{File.basename(__FILE__)}: #{e.class}: #{e}\n"
          msg << e.backtrace.join("\n")
          @logger.error msg
          @dogger.send msg unless e.is_a?(DataDogException) # don't make a loop!
          raise e
        ensure
          cleanup(rds, s3, [ real_data_file, clean_data_file ])
        end
        
        "RDS-S3-Backup Completed Successfully".tap do |t|
          @logger.info t
          @dogger.send t, :alert_type => 'Info', :priority => 'low'
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

      def set_logger_level(ll, q, v)
        ll = 1 if v
        ll = 2 if (ll < 2) && q
        case ll
        when -1 ; Logger::DEBUG
        when 0 ; Logger::INFO
        when 1 ; Logger::WARN
        when 2 ; Logger::ERROR
        when 3 ; Logger::FATAL
        else
          Logger::INFO
        end
      end

      module_function :process_options, :run, :cleanup, :set_logger_level

    end
  end
end
