# app/controllers/spas_controller.rb
class SpasController < ApplicationController
  before_action :set_spa

  def update
    Rails.logger.info("[SPA] update params keys: top=#{params.keys.grep(/stock_image/)} spa=#{params[:spa]&.keys}") if Rails.env.development?

    if @spa.update(spa_params)
      attach_stock_menus(@spa)

      respond_to do |format|
        format.turbo_stream { redirect_to settings_path, notice: t("flash.updated"), status: :see_other }
        format.html        { redirect_to settings_path, notice: t("flash.updated") }
      end
    else
      # editing from Settings#show
      @setting = Setting.first_or_create(name: "Default Setting")
      render "settings/show", status: :unprocessable_entity
    end
  end

  # DELETE /spa/purge_menu_file?attachment_id=123
  def purge_menu_file
    att = @spa.menu_file.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: settings_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  # DELETE /spa/purge_menu_file_es?attachment_id=123
  def purge_menu_file_es
    att = @spa.menu_file_es.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: settings_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  private

  def set_spa
    @spa = Spa.first_or_create!(spa_name: "Spa")
  end

  # Only DB-backed fields (and direct uploads if you add them later).
  # DO NOT permit stock keys here.
  def spa_params
    params.fetch(:spa, {}).permit(:spa_name)
    # If later you allow direct uploads too:
    # params.fetch(:spa, {}).permit(:spa_name, menu_file: [], menu_file_es: [])
  end

  # ---- Stock gallery -> S3 -> attach many files ----
  # Reads TOP-LEVEL params (preferred, like SettingsController map):
  # params[:stock_image_keys_menu_file]
  # params[:stock_image_keys_menu_file_es]
  #
  # Also supports nested values if your JS accidentally submits:
  # params[:spa][:stock_image_keys_menu_file]
  def attach_stock_menus(spa)
    keys_en = stock_keys(:stock_image_keys_menu_file, nested: true)
    keys_es = stock_keys(:stock_image_keys_menu_file_es, nested: true)

    Rails.logger.info("[SPA] keys_en=#{keys_en.inspect} keys_es=#{keys_es.inspect}") if Rails.env.development?

    keys_en.each { |key| attach_s3_file(spa, :menu_file, key) }
    keys_es.each { |key| attach_s3_file(spa, :menu_file_es, key) }
  end

  # Accepts:
  # - nil / blank => []
  # - "s3/key.svg" (single)
  # - "k1,k2,k3" (CSV)
  # - '["k1","k2"]' (JSON array string)
  # - ["k1","k2"] (Rails array params from name="...[]")
  def stock_keys(param_name, nested: false)
    raw =
      if params[param_name].present?
        params[param_name]
      elsif nested
        params.dig(:spa, param_name)
      end

    return [] if raw.blank?

    # Rails array param already
    return raw.map(&:to_s).map(&:strip).reject(&:blank?) if raw.is_a?(Array)

    str = raw.to_s.strip
    return [] if str.blank?

    # JSON array string
    if str.start_with?("[")
      JSON.parse(str).map(&:to_s).map(&:strip).reject(&:blank?)
    else
      # single or CSV
      str.split(",").map(&:strip).reject(&:blank?)
    end
  rescue JSON::ParserError
    []
  end

  # Attach one file from S3 to has_many_attached.
  # Optional: skip if already attached by the same filename to prevent duplicates.
  def attach_s3_file(record, attachment_name, s3_key)
    return if s3_key.blank?

    filename = File.basename(s3_key)

    # Prevent duplicates (optional but helpful)
    already = record.public_send(attachment_name).attachments.any? { |a| a.blob.filename.to_s == filename }
    return if already

    service = S3ImageService.new
    bucket  = service.instance_variable_get(:@bucket)

    s3_object = service.client.get_object(bucket: bucket, key: s3_key)

    io = StringIO.new(s3_object.body.read)
    content_type = s3_object.content_type || "application/octet-stream"

    record.public_send(attachment_name).attach(
      io: io,
      filename: filename,
      content_type: content_type
    )
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[SPA] NoSuchKey: #{s3_key}")
  rescue => e
    Rails.logger.error("[SPA] attach_s3_file error (#{attachment_name}) #{e.class}: #{e.message}")
  end
end
