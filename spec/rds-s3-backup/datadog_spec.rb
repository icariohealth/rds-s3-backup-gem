require 'spec_helper'
require 'dogapi'
require 'rds-s3-backup'

module Rds::S3::Backup

  describe "DataDog" do
    it { DataDog.should respond_to(:new) }

    describe "#make_dog_client" do

      it "should return the client object" do
        Dogapi::Client.stub(:new).with("apikey").and_return("apikey")
        DataDog.new("apikey").make_dog_client.should == "apikey"
      end

      it "should raise an exception" do
        Dogapi::Client.stub(:new) { raise RuntimeError }
        expect { DataDog.new("apikey").make_dog_client }.to raise_error(RuntimeError)
      end

    end

    describe "#send" do
      it "should do something interesting" do
        Dogapi::Client.stub_chain(:new, :emit_event) {"event"}
        Dogapi::Event.stub(:new)
        DataDog.new("apikey").send("message").should == "event"
      end

      it "should raise and exception" do
        Dogapi::Client.stub_chain(:new, :emit_event) { raise RuntimeError }
        expect { DataDog.new("apikey").send("message")}.to raise_error(RuntimeError)
      end



    end




  end

end
