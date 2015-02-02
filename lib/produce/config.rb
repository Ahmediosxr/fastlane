module Produce
  class Config
    ASK_MESSAGES = {
      bundle_identifier: "App Identifier (Bundle ID, e.g. com.krausefx.app): ",
      app_name: "App Name: ",
      version: "Initial version number (e.g. '1.0'): ",
      sku: "SKU Number (e.g. '1234'): ",
      primary_language: "Primary Language (e.g. 'English', 'German'): "
    }

    # Leaved to keep Fastline from crashing. Should be removed upon version bump.
    def self.shared_config
    end

    def self.env_options
      hash = {
        bundle_identifier: ENV['PRODUCE_APP_IDENTIFIER'],
        app_name: ENV['PRODUCE_APP_NAME'],
        version: ENV['PRODUCE_VERSION'],
        sku: ENV['PRODUCE_SKU'],
        skip_itc: skip_itc?(ENV['PRODUCE_SKIP_ITC'])
      }
      if ENV['PRODUCE_LANGUAGE']
        language = ENV['PRODUCE_LANGUAGE']
        if is_valid_language?(language)
          hash[:primary_language] = language
        else
          Helper.log.error "PRODUCE_LANGUAGE is set to #{language} but it's not one of available languages. You'll be asked to set language again if needed."
        end
      end
      hash[:bundle_identifier] ||= CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
      hash.delete_if { |key, value| value.nil? }
      hash
    end

    def initialize(options = {})
      @config = Config.env_options.merge(options)
    end

    def self.val(key)
      raise "Please only pass symbols, no Strings to this method".red unless key.kind_of? Symbol

      unless self.shared_config.config.has_key? key
        self.shared_config.config[key] = ask(ASK_MESSAGES[key]) do |q|
          case key
          when :primary_language
            q.validate = lambda { |val| is_valid_language?(val) }
            q.responses[:not_valid] = "Please enter one of available languages: #{AvailableDefaultLanguages.all_langauges}"
          else
            q.validate = lambda { |val| !val.empty? }
            q.responses[:not_valid] = "#{key.to_s.gsub('_', ' ').capitalize} can't be blank"
          end
        end
      end

      return self.shared_config.config[key]
    end

    def self.is_valid_language? language
      language = language.split.map(&:capitalize).join(' ')
      AvailableDefaultLanguages.all_langauges.include? language
    end

    def self.skip_itc? value
      %w( true t 1 yes y ).include? value.to_s.downcase
    end
  end
end