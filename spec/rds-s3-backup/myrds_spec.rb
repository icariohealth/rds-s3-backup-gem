require 'spec_helper'
require 'rds-s3-backup'
require 'fog'

module Rds::S3::Backup

  describe "MyRDS" do

    let(:myrds_options) {{'aws_access_key_id' => 'abcdef',
      'aws_secret_access_key' => 'xyzzy',
      'region' => 'us-west',
      'rds_instance_id' => 'honeybadger',
      'db_subnet_group_name' => 'test',
      'db_instance_type' => 'big',
      'mysql_username' => 'JoeBob',
      'mysql_password' => 'BillyBriggs',
      'mysql_database' => 'test',
      'dump_directory' => '.',
      'obfuscate_sql' => 'obfuscate_database.sql',
      'timestamp' => Time.new.strftime('%Y-%m-%d-%H-%M-%S-%Z')
    }}
      
    let(:myrds) {MyRDS.new(myrds_options)}

    before(:each) do
      Fog.stub(:timeout=)
      Fog::AWS::RDS.stub(:new) { Object.new }
    end
    
    it ":get_rds_connection should return an exception" do
      Fog::AWS::RDS.stub(:new) { raise RuntimeError }
      expect { myrds.get_rds_connection }.to raise_error(RuntimeError)
    end

    xit "execute :dump" do
      Fog::AWS::RDS.stub_chain(:new, :servers)
      Rds::S3::Backup::MySqlCmds.stub_chain(:new, :dump) {"dumpfile.sql.gz"}
      myrds.dump("dumpfile.sql.gz").should == "dumpfile.sql.gz"
    end

    xit "execute :obfuscate" do
      Rds::S3::Backup::MySqlCmds.stub_chain(:new, :exec)
      myrds.exec(myrds_options['obfuscate_sql']).should == 0
    end

    xit "executing :obfuscate returns an error" do
      Rds::S3::Backup::MySqlCmds.stub_chain(:new, :exec) {raise RuntimeError}
      expect {myrds.exec(myrds_options['obfuscate_sql'])}.to raise_error(RuntimeError)
    end

    
  end


end
