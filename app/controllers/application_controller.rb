class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    dashboard_index_path(locale: I18n.locale) # => /en/dashboard o /es/dashboard
  end

  rescue_from Pundit::NotAuthorizedError do
    redirect_to(root_path, alert: "No tienes permiso para realizar esta acción.")
  end

  before_action :set_locale
  allow_browser versions: :modern
  before_action :load_module_title
  before_action :load_setting

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def load_module_title
    @module_title ||= ModuleTitle.first_or_create
  end

  def load_setting
    @setting ||= Setting.first_or_create(name: "Default Setting")
  end
end