=begin

= rds.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Author(s)*::    Tamara Temple <tamara.temple@novu.com>
*Since*::        2013-02-26
*License*::      GPLv3
*Version*::      0.0.1

== Description

=end

require 'fog'

module Rds::S3::Backup


  class MyRDSException < RuntimeError ; end
  class MyRDS

    def initialize(opts)
      @opts = opts
    end

    def rds
      # Memoize @rds
      @rds ||= get_rds_connection()
    end

    def server
      # Memoize @server
      @server ||= get_rds_server(@opts['rds_instance_id'])
    end


    # Restore the production database from the most recent snapshot
    def restore_db

      begin
        self.rds.restore_db_instance_from_db_snapshot(new_snap.id,
                                                  backup_server_id,
                                                  {"DBSubnetGroupName" => @opts['db_subnet_group_name'],
                                                    "DBInstanceClass" => @opts['db_instance_type'] } )
      rescue Exception => e
        raise MyRDSException.new("Error in #{self.class}:restore_db: #{e.class}: #{e}")
      end

    end


    # Dump the database to the backup file name
    def dump(backup_file_name)
      @mysqlcmds ||= ::Rds::S3::Backup::MySqlCmds.new(backup_server.endpoint['Address'],
                                                      @opts['mysql_username'],
                                                      @opts['mysql_password'],
                                                      @opts['mysql_database'])




      @mysqlcmds.dump(backup_file_path(backup_file_name)) # returns the dump file path
    end

    # Convert personal data in the production data into random generic data 
    def obfuscate
      @mysqlcmds ||= ::Rds::S3::Backup::MySqlCmds.new(backup_server.endpoint['Address'],
                                                      @opts['mysql_username'],
                                                      @opts['mysql_password'],
                                                      @opts['mysql_database'])

      @mysqlcmds.exec(@opts['obfuscate_sql'])
    end

    def backup_file_path(backup_file_name)
      File.join(@opts['dump_directory'], backup_file_name)    
    end

    def backup_server_id
      @backup_server_id ||= "#{self.server.id}-s3-dump-server-#{@opts['timestamp']}"
    end

    def new_snap
      unless @new_snap
        self.server.snapshots.new(:id => snap_name).save
        @new_snap = self.server.snapshots.get(snap_name)

        (0..1).each {|i|  $logger.debug "#{__FILE__}:#{__LINE__}: Waiting for new_snap server to be ready: #{i}"; @new_snap.wait_for { ready? } } # ready? sometimes lies

      end

      @new_snap
    end

    def backup_server
      @backup_server ||= get_rds_server(backup_server_id)

      (0..1).each {|i|  $logger.debug "#{__FILE__}:#{__LINE__}: Waiting for backup_server to be ready: #{i}" ;  @backup_server.wait_for {ready? } } # won't get fooled again!
      @backup_server

    end

    def snap_name
      @snap_name ||= "s3-dump-snap-#{@opts['timestamp']}"
    end

    def get_rds_connection()
      options = {
        :aws_access_key_id => @opts['aws_access_key_id'],
        :aws_secret_access_key => @opts['aws_secret_access_key'],
        :region => @opts['aws_region']}
      Fog.timeout=@opts['fog_timeout']
      begin
        connection = Fog::AWS::RDS.new(options)
      rescue Exception => e
        raise MyRDSException.new("Error in #{self.class}#get_rds_connection: #{e.class}: #{e}")
      end
      
      raise MyRDSException.new("Unable to make RDS connection") if connection.nil?

      connection

    end

    def get_rds_server(id)

       begin
        server = self.rds.servers.get(id)
      rescue Exception => e
        raise MyRDSException.new("Error getting server in #{self.class}#get_rds_server: #{e.class}: #{e}")
      end
      raise MyRDSException.new("Server is nil for #{id}") if server.nil?
      server
    end


    def destroy
      
      unless @new_snap.nil?
        (0..1).each {|i| $logger.debug "#{__FILE__}:#{__LINE__}: Waiting for new_snap server to be ready in #{self.class}#destroy: #{i}"; @new_snap.wait_for { ready? } }
        @new_snap.destroy
      end
      
      unless @backup_server.nil?
        (0..1).each {|i|  $logger.debug "#{__FILE__}:#{__LINE__}: Waiting for backup server to be ready in #{self.class}#destroy: #{i}"; @backup_server.wait_for {ready? } }
        @backup_server.destroy(nil)
      end

    end



  end

end
