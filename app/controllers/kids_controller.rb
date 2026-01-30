class KidsController < ApplicationController
  before_action :set_kids

  def show
  end

  def update
    Rails.logger.info("[KIDS] update params keys: top=#{params.keys.grep(/stock_image/)} kids=#{params[:kid]&.keys}") if Rails.env.development?

    if @kids.update(kids_params)
      attach_stock_menus(@kids)

      respond_to do |format|
        format.turbo_stream { redirect_to kids_path, notice: t("flash.updated"), status: :see_other }
        format.html        { redirect_to kids_path, notice: t("flash.updated") }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def purge_menu_file
    att = @kids.menu_file.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: kids_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  def purge_menu_file_es
    att = @kids.menu_file_es.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: kids_path,
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  private

  def set_kids
    @kids = Kid.first_or_create!(kids_name: "Kids Club")
  end

  def kids_params
    params.fetch(:kid, {}).permit(:kids_name)
  end

  def attach_stock_menus(kids)
    keys_en = stock_keys(:stock_image_keys_menu_file, nested: true)
    keys_es = stock_keys(:stock_image_keys_menu_file_es, nested: true)

    Rails.logger.info("[KIDS] keys_en=#{keys_en.inspect} keys_es=#{keys_es.inspect}") if Rails.env.development?

    keys_en.each { |key| attach_s3_file(kids, :menu_file, key) }
    keys_es.each { |key| attach_s3_file(kids, :menu_file_es, key) }
  end

  def stock_keys(param_name, nested: false)
    raw =
      if params[param_name].present?
        params[param_name]
      elsif nested
        params.dig(:kid, param_name)
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
    Rails.logger.warn("[KIDS] NoSuchKey: #{s3_key}")
  rescue => e
    Rails.logger.error("[KIDS] attach_s3_file error (#{attachment_name}) #{e.class}: #{e.message}")
  end
end
