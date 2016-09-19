module Fluent
  class GelfOutput < BufferedOutput

    Plugin.register_output('gelf', self)

    config_param :host, :string, :default => nil
    config_param :port, :integer, :default => 12201
    config_param :full_message_key, :string, :default => 'log'
    config_param :short_message_key, :string, :default => 'gelf.message'
    config_param :host_key, :string, :default => 'gelf.host'
    config_param :level_key, :string, :default => 'gelf.level'

    def initialize
      super
      require 'gelf'
    end

    def configure(conf)
      super
      @id_to_cfg = {}
    end

    def start
      super
      @conn = GELF::Notifier.new(@host, @port, 'WAN', { :facility => 'fluentd' })
      @conn.level_mapping = 'direct'
      @conn.collect_file_and_line = false
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      msec = time.nsec / 1000000
      gelfentry = { :timestamp => (time.to_s + "." + msec.to_s).to_f, :tag => tag };
      gelfentry[:version] = '1.1';
      gelfentry[:full_message] = record[@full_message_key];
      gelfentry[:short_message] = record[@short_message_key];
      gelfentry[:level] = record[@level_key];

      record.each_pair do |k,v|
        case k
        when @short_message_key, @full_message_key, @host_key, @level_key then
        else gelfentry['_' + k] = v end
      end

      if gelfentry[:level].nil? then
        gelfentry[:level] = GELF::UNKNOWN
      else
        normalize_level(gelfentry)
      end

      if gelfentry[:short_message].nil? then
        gelfentry[:short_message] = record.to_json
      end

      gelfentry[:short_message] = uncolorize(gelfentry[:short_message])

      gelfentry.to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each do |data|
        @conn.notify!(data)
      end
    end

    private

    def uncolorize(string)
      string.gsub(/\033\[\d{1,2}(;\d{1,2}){0,2}[mGK]/, '')
    end

    def normalize_level(entry)
      case entry[:level].to_s.downcase
      # gelf-rb only supports a subset of these levels
      when '0', 'emergency' then entry[:level] = GELF::FATAL
      when '1', 'alert' then entry[:level] = GELF::FATAL
      when '2', 'critical', 'crit' then entry[:level] = GELF::FATAL
      when '3', 'error', 'err', 'e' then entry[:level] = GELF::ERROR
      when '4', 'warning', 'warn', 'w' then entry[:level] = GELF::WARN
      when '5', 'notice' then entry[:level] = GELF::WARN
      when '6', 'informational', 'info', 'i' then entry[:level] = GELF::INFO
      when '7', 'debug', 'd' then entry[:level] = GELF::DEBUG
      else entry[:level] = GELF::UNKNOWN
      end
    end
  end
end
