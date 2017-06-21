require 'time'

module Appfuel
  class LogFormatter < Logger::Formatter
    def self.call(severity, time, progname, msg)
      "#{progname} #{time.utc.iso8601} p-#{Process.pid} #{severity}: #{msg}\n"
    end
  end
end
