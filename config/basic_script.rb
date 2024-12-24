# frozen_string_literal: true

module Scripts
  module BasicScript

    module ClassMethods
      # Initialization before calling the script
      def call(**args)
        new(**args).call
      end
    end

    def self.prepended(base)
      base.extend Dry::Initializer[undefined: false]
      base.extend ClassMethods
      # Event log settings
      base.option :log_level, default: proc { Logger::INFO }
      base.option :stripe_script_logger, default: proc { build_stripe_script_logger(level: @log_level) }

      # Script log settings
      base.option :logger, default: proc { Application.logger }
    end

    def build_stripe_script_logger(level:)
      logger = Logger.new(STDOUT)
      logger.level = level
      logger.formatter = proc { |severity, datetime, _progname, msg|
        "#{datetime} [#{severity}] #{msg}\n"
      }
      logger
    end

    # Override the script call to return the state
    def call
      super

      self
    end

  end
end