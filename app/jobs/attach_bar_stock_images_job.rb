class AttachBarStockImagesJob < ApplicationJob
  queue_as :default

  def perform(bar_id, logo_key: nil, menu_en_key: nil, menu_es_key: nil)
    bar = Bar.find_by(id: bar_id)
    return unless bar

    service = S3ImageService.new
    bucket  = service.bucket
    client  = service.client

    attach_via_server_copy(bar, :menu_file,    bucket, client, menu_en_key) if menu_en_key.present?
    attach_via_server_copy(bar, :menu_file_es, bucket, client, menu_es_key) if menu_es_key.present?
    attach_via_server_copy(bar, :logo,         bucket, client, logo_key)    if logo_key.present?

    # Nada de precálculo de variantes (on-demand con vips).
    # Tampoco recargamos el modelo para evitar trabajo extra.

 
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[AttachBarStockImagesJob] NoSuchKey for one of: #{[logo_key, menu_en_key, menu_es_key].compact.join(', ')}")
  rescue => e
    Rails.logger.error("[AttachBarStockImagesJob] #{e.class} #{e.message}")
  end

  private

  # Igual que Activity: creamos el blob con checksum (ETag→MD5 base64),
  # copiamos dentro de S3 y luego attach al attachment correspondiente.
  def attach_via_server_copy(record, attachment_name, bucket, client, source_key)
    filename = File.basename(source_key)

    head         = client.head_object(bucket: bucket, key: source_key)
    content_type = head.content_type || "application/octet-stream"
    byte_size    = head.content_length
    etag_hex     = head.etag.delete('"')

    # Nota: si el ETag es multipart (incluye "-"), no es un MD5 puro.
    # Lo avisamos para diagnóstico, replicando la misma filosofía que usamos en otros jobs.
    if etag_hex.include?("-")
      Rails.logger.warn("[AttachBarStockImagesJob] Multipart ETag for #{source_key}; MD5 checksum may not match")
    end

    checksum = Base64.strict_encode64([etag_hex].pack("H*"))

    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename:     filename,
      byte_size:    byte_size,
      content_type: content_type,
      checksum:     checksum,
      service_name: ActiveStorage::Blob.service.name
    )

    client.copy_object(
      bucket:      bucket,
      copy_source: "#{bucket}/#{source_key}",
      key:         blob.key
    )

    record.public_send(attachment_name).attach(blob)
  end
end