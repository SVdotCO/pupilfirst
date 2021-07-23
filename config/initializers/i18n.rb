module I18nJS
  def self.translations
    ::I18n.backend.send(:init_translations)
    ::I18n.backend.send(:translations)
  end
end

I18n.available_locales = ENV['I18N_AVAILABLE_LOCALES'].split(',')
I18n.default_locale = ENV['I18N_DEFAULT_LOCALE']
