=begin

= rds-s3-backup_spec.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Author(s)*::    Tamara Temple <tamara.temple@novu.com>
*Since*::        2013-02-26
*License*::      GPLv3
*Version*::      0.0.1

== Description

=end

require 'rds-s3-backup'


module Rds::S3::Backup

  describe "has version" do
    it {Rds::S3::Backup::VERSION.should == '0.0.1' }
  end
  
  describe "module methods" do
    
    it { Rds::S3::Backup.should respond_to(:run) }
    it { Rds::S3::Backup.should respond_to(:process_options) }
    it { Rds::S3::Backup.should respond_to(:cleanup) }
    it { Rds::S3::Backup.should respond_to(:set_logger_level) }
  end

  describe "#run method" do
      let(:options) { {
          :rds_instance_id => 'stagingdb',
          :s3_bucket => 'novu-backups',
          :backup_bucket => 'novu-backups',
          :s3_prefix => 'db_dumps',
          :aws_access_key_id => 'ABCDE',
          :aws_secret_access_key => '0987654321',
          :mysql_database => 'novu_text',
          :mysql_username => 'novurun',
          :mysql_password => 'passw0rd',
          :obfuscate_sql => '/usr/local/etc/obfuscate.sql',
          :dump_ttl => 0,
          :dump_directory => '/mnt/secure',
          :aws_region => 'us-east-1',
          :aws_s3_region => 'us-west-2',
          :db_subnet_group_name => 'staging db subnet',
          :db_instance_type => 'db.m1.small',
          :instance_id => '',
          :log_level => 0,
          :quiet => false,
          :verbose => true
        } }


    before(:each) do
      DataDog.stub(:new).and_return(OpenStruct.new(:send => true))

      MyRDS.stub(:new).and_return(OpenStruct.new(:restore_db => true,
                                                 :dump => Proc.new {|file| file },
                                                 :obfuscate => true,
                                                 :destroy => true,
                                                 :server =>
                                                 OpenStruct.new(:id => 1)
                                                 ))
      MyS3.stub(:new).and_return(OpenStruct.new(:save_production => true,
                                                :save_clean => true,
                                                :prune_files => true,
                                                :destroy => true))
    end

    it "should process options" do
      opts = Rds::S3::Backup.process_options(options)
      opts.should be_a(Hash)
      opts.should have_key(:timestamp)
      opts[:timestamp].should_not be_nil
    end


    it { Rds::S3::Backup.run(options).should == 0 }

  end

end
