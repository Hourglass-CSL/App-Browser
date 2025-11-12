class AttachActivityCoverImageJob < ApplicationJob
  queue_as :default

  def perform(activity_id, cover_key:)
    activity = Activity.find_by(id: activity_id)
    return unless activity
    return if cover_key.blank?

    service = S3ImageService.new
    bucket  = service.bucket
    client  = service.client

    filename = File.basename(cover_key)

    # HEAD → metadatos
    head         = client.head_object(bucket: bucket, key: cover_key)
    content_type = head.content_type || "application/octet-stream"
    byte_size    = head.content_length
    etag         = head.etag.delete('"') # ETag sin comillas
    checksum     = Base64.strict_encode64([etag].pack("H*")) # convertir MD5 hex a base64

    # Crear blob en ActiveStorage con checksum
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: filename,
      byte_size: byte_size,
      content_type: content_type,
      checksum: checksum,
      service_name: ActiveStorage::Blob.service.name
    )

    # Copia directa dentro de S3 (sin pasar por el dyno)
    client.copy_object(
      bucket: bucket,
      copy_source: "#{bucket}/#{cover_key}",
      key: blob.key
    )

    # Adjuntar al modelo
    activity.cover_image.attach(blob)

  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[AttachActivityCoverImageJob] NoSuchKey for #{cover_key}")
  rescue => e
    Rails.logger.error("[AttachActivityCoverImageJob] #{e.class} #{e.message}")
  end
end