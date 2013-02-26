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

  attr_accessor :rds, :server

  def initialize(opts)
    @opts = opts

    @rds = get_rds_connection(:aws_access_key_id => @opts['aws_access_key_id'],
                              :aws_secret_access_key => @opts['aws_secret_access_key'],
                              :region => @opts['aws_region'])

    @server = get_rds_server(@opts['rds_instance_id'])

    @mysqlcmds = ::Rds::S3::Backup::MySqlCmds.new(backup_server.endpoint['Address'],
                               @opts['mysql_username'],
                               @opts['mysql_password'],
                               @opts['mysql_database'])

  end

  def restore_db

    begin
      @rds.restore_db_instance_from_db_snapshot(new_snap.id,
                                                backup_server_id,
                                                {"DBSubnetGroupName" => @opts['db_subnet_group_name'],
                                                  "DBInstanceClass" => @opts['db_instance_type'] } )
    rescue Exception => e
      raise MyRDSException.new("Error in #{self.class}:restore_db: #{e.class}: #{e}")
    end

  end


  def dump(backup_file_name)
    @mysqlcmds.dump(backup_file_path(backup_file_name)) # returns the dump file path
  end

  def obfuscate
    @mysqlcmds.exec(@opts['obfuscate_sql'])
  end

  def backup_file_path(backup_file_name)
    File.join(@opts['dump_directory'], backup_file_name)    
  end

  def backup_server_id
    @backup_server_id ||= "#{@server.id}-s3-dump-server-#{@opts['timestamp']}"
  end

  def backup_server
    @backup_server ||= get_rds_server(backup_server_id)

    (0..2).each {|i| @backup_server.wait_for { ready? } } # won't get fooled again!
    @backup_server

  end

  def new_snap
    unless @new_snap
      self.server.snapshots.new(:id => snap_name).save
      @new_snap = self.server.snapshots.get(snap_name)

      (0..2).each {|i| @new_snap.wait_for { ready? } } # ready? sometimes lies

    end

    @new_snap
  end

  def snap_name
    @snap_name ||= "s3-dump-snap-#{@opts['timestamp']}"
  end

  def get_rds_connection(opts={})
    options = {
      :aws_access_key_id => @opts['aws_access_key_id'],
      :aws_secret_access_key => @opts['aws_secret_access_key'],
      :region => @opts['aws_region']}.merge(opts)
    
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
      server = @rds.servers.get(id)
    rescue Exception => e
      raise MyRDSException.new("Error getting server in #{self.class}#get_rds_server: #{e.class}: #{e}")
    end
    raise MyRDSException.new("Server is nil for #{id}") if server.nil?
    server
  end


  def destroy
    
    unless @new_snap.nil?
      (0..2).each {|i| @new_snap.wait_for { ready? } }
      @new_snap.destroy
    end
    
    unless @backup_server.nil?
      (0..2).each {|i| @backup_server.wait_for { ready? } }
      @backup_server.destroy(nil)
    end

  end



end

end
