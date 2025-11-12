class Admin::BaseController < ApplicationController
  before_action :ensure_admin!

  private

  def ensure_admin!
    authorize(:application, :admin_only?)
  end
end