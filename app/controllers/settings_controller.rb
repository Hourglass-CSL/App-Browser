class SettingsController < ApplicationController
  before_action :set_setting

def show
   @spa = Spa.first_or_create!(spa_name: "Spa")
   @kids = Kid.first_or_create!(kids_name: "Kids Club")
end

  def edit
  end

  def update
    if setting_params[:remove_qr_code] == "1"
      @setting.qr_code.purge_later
    end

    if @setting.update(setting_params.except(:stock_image_key_logo, :stock_image_key_map, :stock_image_key_qr_code, :remove_qr_code))
      attach_stock_images(@setting)
      respond_to do |format|
        format.turbo_stream { redirect_to settings_path, notice: t("flash.updated"), status: :see_other }
        format.html        { redirect_to settings_path, notice: t("flash.updated") }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def attach_stock_images(setting)
    if params[:stock_image_key_qr_code].present?
      attach_s3_file(setting, :qr_code, params[:stock_image_key_qr_code])
    end

    if params[:stock_image_key_map].present?
      attach_s3_file(setting, :map, params[:stock_image_key_map])
    end

    if params[:stock_image_key_logo].present?
      attach_s3_file(setting, :logo, params[:stock_image_key_logo])
    end
  end

  def attach_s3_file(record, attachment_name, s3_key)
    return if s3_key.blank?
    service = S3ImageService.new
    s3_object = service.client.get_object(bucket: service.instance_variable_get(:@bucket), key: s3_key)
    io = StringIO.new(s3_object.body.read)
    filename = File.basename(s3_key)
    content_type = s3_object.content_type || "application/octet-stream"
    record.send(attachment_name).attach(io: io, filename: filename, content_type: content_type)
  end

  private

  def set_setting
    @setting = Setting.first_or_create(name: "Default Setting")
  end

  def setting_params
    params.fetch(:setting, {}).permit(:qr_code, :map, :logo, :stock_image_key_qr_code, :stock_image_key_map, :stock_image_key_logo, :remove_qr_code)
  end
end