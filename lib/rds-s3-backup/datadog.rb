=begin

= datadog.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Author(s)*::    Tamara Temple <tamara.temple@novu.com>
*Since*::        2013-02-26
*License*::      GPLv3
*Version*::      0.0.1

== Description

=end

module Rds
  module S3
    module Backup
      class DataDogException < RuntimeError ; end
      class DataDog

        def initialize(api_key)
          raise DataDogException.new("No DataDog API given") if api_key.nil? || api_key.empty?
          @api_key = api_key
        end

        def make_dog_client()
          return unless @api_key
          begin
            Dogapi::Client.new(@api_key)
          rescue Exception => e
            unless e.is_a?(DataDogException) # no loops!
              raise DataDogException.new "Error setting up DataDog connection: #{e.class}: #{e}"
            end
          end
        end


        def send(msg, o={})
          return unless @api_key

          return if msg.nil? || msg.empty?

          options = {
            :msg_title => 'Message from rds-s3-backup:',
            :alert_type => 'Error',
            :tags => [ "host:#{`hostname`}", "env:production" ],
            :priority => 'normal',
            :source => 'My Apps'}.merge(o)

          @dog_client ||= make_dog_client()

          begin
            @dog_client.emit_event(Dogapi::Event.new(msg, options))
          rescue Exception => e
            unless e.is_a?(DataDogException) # no loops!
              raise DataDogException.new "Error sending #{msg} to DataDog with options #{options.inspect}: #{e.class}: #{e.message}"
            end
          end
        end

      end

    end
  end
end
