class AttachSpecialCoverImageJob < ApplicationJob
  queue_as :default

  def perform(special_id, cover_key:)
    special = Special.find_by(id: special_id)
    return unless special
    return if cover_key.blank?

    service = S3ImageService.new
    bucket  = service.bucket
    client  = service.client

    filename = File.basename(cover_key)

    # HEAD → metadatos
    head         = client.head_object(bucket: bucket, key: cover_key)
    content_type = head.content_type || "application/octet-stream"
    byte_size    = head.content_length
    etag         = head.etag.delete('"')                         # ETag sin comillas
    checksum     = Base64.strict_encode64([etag].pack("H*"))     # MD5 hex → base64

    # Crear blob en ActiveStorage con checksum
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename:     filename,
      byte_size:    byte_size,
      content_type: content_type,
      checksum:     checksum,
      service_name: ActiveStorage::Blob.service.name
    )

    # Copia directa S3->S3 (server-side), sin pasar por el dyno
    client.copy_object(
      bucket:      bucket,
      copy_source: "#{bucket}/#{cover_key}",
      key:         blob.key
    )

    # Adjuntar al modelo
    special.cover_image.attach(blob)

    # Variantes: se generan on-demand con :vips (sin precálculo aquí)
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[AttachSpecialCoverImageJob] NoSuchKey for #{cover_key}")
  rescue => e
    Rails.logger.error("[AttachSpecialCoverImageJob] #{e.class} #{e.message}")
  end
end