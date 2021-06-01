# -*- encoding: utf-8 -*-

module Fluent
  class ClickHouseOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('clickhouse-output', self)

    include Fluent::SetTimeKeyMixin
    include Fluent::SetTagKeyMixin

    config_param :host, :string, :default => 'localhost'
    config_param :port, :string, :default => 8192
    config_param :urls, :string, :default => nil
    config_param :database, :string, :default => 'default'
    config_param :username, :string, :default => 'default'
    config_param :password, :string, :default => nil, :secret => true

    config_param :table, :string, :default => nil
    config_param :columns, :string, :default => nil

    attr_accessor :handler
    attr_accessor :path

    def initialize
      super

      require 'clickhouse'
    end

    unless method_defined?(:log)
      define_method('log') { $log }
    end

    def configure(conf)
      super
      if conf['columns']
        @columns = conf['columns'].split(',').map { |m| m.strip }
      end
      @config = {}
      if conf['username']
        @config['username'] = conf['username']
      end
      if conf['password']
        @config['password'] = conf['password']
      end

      if conf['urls']
        @urls = @urls.split(',').map { |m| m.strip }
      elsif conf['host']
        @config['host'] = conf['host']
      end
      if conf['port']
        @config['port'] = conf['port']
      end

      @config['database'] = conf['database']
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      Clickhouse.establish_connection(@config)
      Clickhouse.connection.insert_rows(@table, :names => @columns) { |rows|
        chunk.msgpack_each { |tag, time, record|
          rows << @columns.map { |m| record[m] }
        }
        rows
      }
    end
  end
end
