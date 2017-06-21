Appfuel::Initialize.define('global.logging') do |config, container|
  log_file  = config[:logfile] || 'stdout'
  log_level = config[:log_level] || 'info'

  logfile_coercer = ->(file) {
    file = file.to_s
    if file.empty? || file.downcase == 'stdout'
      file = $stdout
    elsif file.downcase == 'stderr'
      file = $stderr
    else
      file
    end
  }

  log_formatter = Appfuel::LogFormatter

  logger_factory = ->(file, level = nil, formatter = nil) {
    logger = Logger.new(file)
    if level
      logger.level = Logger.const_get(level.to_s.upcase)
    end

    if formatter
      logger.formatter = log_formatter
    end

    logger
  }

  logger = logger_factory.call(log_file, log_level, log_formatter)
  container.register(:log_formatter, log_formatter)
  container.register(:logfile_coercer, logfile_coercer)
  container.register(:logger_factory, logger_factory)
  container.register(:logger, logger)
end
