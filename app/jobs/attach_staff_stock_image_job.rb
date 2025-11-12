class AttachStaffStockImageJob < ApplicationJob
  queue_as :default

  def perform(staff_id, profile_key:)
    staff = Staff.find_by(id: staff_id)
    return unless staff
    return if profile_key.blank?

    service = S3ImageService.new
    bucket  = service.bucket
    client  = service.client

    filename = File.basename(profile_key)

    # HEAD → metadatos
    head         = client.head_object(bucket: bucket, key: profile_key)
    content_type = head.content_type || "application/octet-stream"
    byte_size    = head.content_length
    etag         = head.etag.delete('"') # ETag sin comillas
    checksum     = Base64.strict_encode64([etag].pack("H*")) # convertir MD5 hex a base64
 
    # Crear blob en ActiveStorage con checksum
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename:     filename,
      byte_size:    byte_size,
      content_type: content_type,
      checksum:     checksum,                     
      service_name: ActiveStorage::Blob.service.name
    )

    blob.update!(metadata: blob.metadata.merge(analyzed: true))

    # Copia directa dentro de S3 (no pasa por el dyno)
    client.copy_object(
      bucket:      bucket,
      copy_source: "#{bucket}/#{profile_key}",
      key:         blob.key
    )

    # Adjuntar al modelo
    staff.profile_picture.attach(blob)

    # Sin precálculo de variantes (VIPS on-demand)
    staff.reload

    staff.broadcast_replace_to "staff_list",
      target:  "staff_#{staff.id}",
      partial: "staffs/staff_card",
      locals:  { staff: staff }

  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[AttachStaffStockImageJob] NoSuchKey for #{profile_key}")
  rescue => e
    Rails.logger.error("[AttachStaffStockImageJob] #{e.class} #{e.message}")
  end
end