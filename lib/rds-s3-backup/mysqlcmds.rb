=begin

= mysqldcmds.rb

*Copyright*::    (C) 2013 by Novu, LLC
*Author(s)*::    Tamara Temple <tamara.temple@novu.com>
*Since*::        2013-02-26
*License*::      GPLv3
*Version*::      0.0.1

== Description

=end

module Rds::S3::Backup

  class MySqlCmdsException < RuntimeError ; end
  class MySqlCmds
    attr_accessor :host, :user, :passwd, :dbname

    def initialize(host, user, passwd, dbname)

      # Assert real parameters
      raise MySqlCmdsException.new("host is empty") if host.nil? || host.empty?
      raise MySqlCmdsException.new("user is empty") if user.nil? || user.empty?
      raise MySqlCmdsException.new("passwd is empty") if passwd.nil? || passwd.empty?
      raise MySqlCmdsException.new("dbname is empty") if dbname.nil? || dbname.empty?
      
      # Store instance vars
      @host = host
      @user = user
      @passwd = passwd
      @dbname = dbname

      # Find commands to execute
      @mysqldump = `which mysqldump`.chomp
      raise MySqlCmdsException.new("No mysqldump command found") if @mysqldump.empty?
      @mysql = `which mysql`.chomp
      raise MySqlCmdsException.new("No mysql command found") if @mysql.empty?
      @gzip = `which gzip`.chomp
      raise MySqlCmdsException.new("No gzip command found") if @gzip.empty?

    end

    def dump(output)
      raise MySqlCmdsException.new("output is not specified") if output.nil? || output.empty?

      dump_opts = ["--opt",
                   "--add-drop-table",
                   "--single-transaction",
                   "--order-by-primary",
                   "--host=#{@host}",
                   "--user=#{@user}",
                   "--password=XXPASSWORDXX",
                   @dbname]

      gzip_opts = ["--fast",
                   "--stdout",
                   "> #{output}"]


      cmd = "#{@mysqldump} #{dump_opts.join(' ')} | #{@gzip} #{gzip_opts.join(' ')}"

      run(cmd.gsub(/XXPASSWORDXX/,@passwd))
      
      output                      # return the dump file path

    end

    def exec(script)

      return if script.nil? || script.empty?
      raise MySqlCmdsException.new("#{script} is not readable!") unless File.readable?(script)

      obf_opts = ["--host=#{@host}",
                  "--user=#{user}",
                  "--password=XXPASSWORDXX",
                  @dbname]


      cmd = "#{mysql} #{obf_opts.join(' ')} < #{script}"

      run(cmd.gsub(/XXPASSWORDXX/,@passwd))

    end

    def run(cmd)

      result = _really_run_it(cmd)
      if result.code != 0
        error = "Mysql operation failed on  mysql://#{@user}@#{@host}/#{@dbname}: Error code: #{result.code}.\n"
        error << "Command:\n#{cmd}\n"
        error << "stdout:\n#{result.stdout.join("\n")}\n"
        error << "stderr:\n#{result.stderr.join("\n")}\n"
        raise MySqlCmdsException.new error
      end
      

    end

    def _really_run_it(cmd)
      result = Struct.new :stdout, :stderr, :code
      result.stdout = Array.new
      result.stderr = Array.new
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close
        until stdout.eof
          result.stdout << stdout.gets.chomp
        end 
        stdout.close
        until stderr.eof
          result.stderr << stderr.gets.chomp
        end
        stderr.close
        result.code = wait_thr.value
      end
      result
    end

  end



end
