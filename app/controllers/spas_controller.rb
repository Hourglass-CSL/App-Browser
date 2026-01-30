class SpasController < ApplicationController
  before_action :set_spa

    def show
    end

  def update
    Rails.logger.info("[SPA] update params keys: top=#{params.keys.grep(/stock_image/)} spa=#{params[:spa]&.keys}") if Rails.env.development?

    if @spa.update(spa_params)
      attach_stock_menus(@spa)

      respond_to do |format|
        format.turbo_stream { redirect_to spa_path, notice: t("flash.updated"), status: :see_other }
        format.html        { redirect_to spa_path, notice: t("flash.updated") }
      end
    else
      @setting = Setting.first_or_create(name: "Default Setting")
      render "settings/show", status: :unprocessable_entity
    end
  end

  def purge_menu_file
    att = @spa.menu_file.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: spa_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  def purge_menu_file_es
    att = @spa.menu_file_es.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: spa_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  private

  def set_spa
    @spa = Spa.first_or_create!(spa_name: "Spa")
  end

  def spa_params
    params.fetch(:spa, {}).permit(:spa_name)
  end

  def attach_stock_menus(spa)
    keys_en = stock_keys(:stock_image_keys_menu_file, nested: true)
    keys_es = stock_keys(:stock_image_keys_menu_file_es, nested: true)

    Rails.logger.info("[SPA] keys_en=#{keys_en.inspect} keys_es=#{keys_es.inspect}") if Rails.env.development?

    keys_en.each { |key| attach_s3_file(spa, :menu_file, key) }
    keys_es.each { |key| attach_s3_file(spa, :menu_file_es, key) }
  end

  def stock_keys(param_name, nested: false)
    raw =
      if params[param_name].present?
        params[param_name]
      elsif nested
        params.dig(:spa, param_name)
      end

    return [] if raw.blank?

    return raw.map(&:to_s).map(&:strip).reject(&:blank?) if raw.is_a?(Array)

    str = raw.to_s.strip
    return [] if str.blank?

    if str.start_with?("[")
      JSON.parse(str).map(&:to_s).map(&:strip).reject(&:blank?)
    else
      str.split(",").map(&:strip).reject(&:blank?)
    end
  rescue JSON::ParserError
    []
  end


  def attach_s3_file(record, attachment_name, s3_key)
    return if s3_key.blank?

    filename = File.basename(s3_key)
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
