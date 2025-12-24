Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.action_dispatch.default_headers.merge!({
    'X-Frame-Options' => 'ALLOWALL'
  })

  # Heroku: sirve estáticos si el env var está definido
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # No recompilar en runtime
  config.assets.compile = false

  # === Active Storage: usa S3 y sirve por proxy ===
  config.active_storage.service = :amazon
  config.active_storage.resolve_model_to_route = :rails_storage_redirect
  config.active_storage.service_urls_expire_in = 1.hour
  # (opcional) si alguna vez vuelves a redirect:
  # config.active_storage.service_urls_expire_in = 24.hours
  config.active_storage.variant_processor = :vips

  # SSL
  config.force_ssl = true

  # Logging
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # URLs absolutas correctas para tu dominio
  Rails.application.routes.default_url_options[:host] = "gfa.hourglass.com.mx"
  Rails.application.routes.default_url_options[:protocol] = "https"
  config.action_controller.default_url_options = { host: "gfa.hourglass.com.mx", protocol: "https" }

  # (opcional) si tienes CDN delante:
  # config.asset_host = "https://gfa.hourglass.com.mx"
end
