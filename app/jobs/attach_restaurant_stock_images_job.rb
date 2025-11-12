class AttachRestaurantStockImagesJob < ApplicationJob
  queue_as :default

  def perform(restaurant_id, logo_key: nil, menu_en_key: nil, menu_es_key: nil)
    restaurant = Restaurant.find_by(id: restaurant_id)
    return unless restaurant

    service = S3ImageService.new
    bucket  = service.bucket        # usa el accessor como en Activity
    client  = service.client

    attach_via_s3_copy(restaurant, :logo,         logo_key,    client, bucket) if logo_key.present?
    attach_via_s3_copy(restaurant, :menu_file,    menu_en_key, client, bucket) if menu_en_key.present?
    attach_via_s3_copy(restaurant, :menu_file_es, menu_es_key, client, bucket) if menu_es_key.present?

    # Igual que en Activity: nada de reload/broadcast/variant aquí.
  rescue => e
    Rails.logger.error("[AttachRestaurantStockImagesJob] #{e.class} #{e.message}")
  end

  private

  def attach_via_s3_copy(record, attachment_name, s3_key, client, bucket)
    filename = File.basename(s3_key)

    # HEAD → para content_type, size y ETag
    head         = client.head_object(bucket: bucket, key: s3_key)
    content_type = head.content_type || "application/octet-stream"
    byte_size    = head.content_length
    etag_raw     = head.etag.delete('"')

    # Si es multipart ETag, avisamos (no es MD5 puro)
    if etag_raw.include?("-")
      Rails.logger.warn("[AttachRestaurantStockImagesJob] Multipart ETag for #{s3_key}; MD5 checksum no disponible")
    end

    checksum = Base64.strict_encode64([etag_raw].pack("H*")) # MD5 hex → base64

    # Blob "vacío" con checksum
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename:     filename,
      byte_size:    byte_size,
      content_type: content_type,
      checksum:     checksum,
      service_name: ActiveStorage::Blob.service.name
    )

    # Copia server-side dentro de S3 (no toca el dyno)
    client.copy_object(
      bucket:      bucket,
      copy_source: "#{bucket}/#{s3_key}",
      key:         blob.key
    )

    # Adjuntar al modelo
    record.public_send(attachment_name).attach(blob)
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[AttachRestaurantStockImagesJob] NoSuchKey for #{s3_key}")
  end
end