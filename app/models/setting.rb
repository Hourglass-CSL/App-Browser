class Setting < ApplicationRecord
  has_one_attached :qr_code
  has_one_attached :map
  has_one_attached :logo


   after_update_commit -> {
     broadcast_replace_to("settings", target: "setting_qr",   partial: "settings/qr",   locals: { setting: self })
     broadcast_replace_to("settings", target: "setting_map",  partial: "settings/map",  locals: { setting: self })
     broadcast_replace_to("settings", target: "setting_logo", partial: "settings/logo", locals: { setting: self })
   }

  validate :qr_code_format
  validate :map_file_type
  validate :logo_file_type

  private

  # Normaliza el content_type (corrige application/octet-stream, etc.)
  def normalized_content_type_for(blob)
    ct = blob.content_type.presence
    return ct if ct.present? && ct != "application/octet-stream"

    # Fallback: deduce por nombre/extensión
    Marcel::MimeType.for(Pathname.new(blob.filename.to_s), name: blob.filename.to_s)
  end

  def qr_code_format
    return unless qr_code.attached?

    ct = normalized_content_type_for(qr_code.blob)
    allowed = %w[image/png image/jpeg image/gif image/webp image/x-webp image/svg+xml]
    unless allowed.include?(ct)
      errors.add(:qr_code, "must be PNG, JPG, GIF, WEBP o SVG")
    end
  end

  def map_file_type
    return unless map.attached?

    ct = normalized_content_type_for(map.blob)
    allowed = %w[image/png image/jpeg image/gif image/webp image/x-webp image/svg+xml application/pdf]
    unless allowed.include?(ct)
      errors.add(:map, "must be PNG, JPG, GIF, WEBP, SVG o PDF")
    end
  end

  def logo_file_type
    return unless logo.attached?

    ct = normalized_content_type_for(logo.blob)
    allowed = %w[image/png image/jpeg image/gif image/webp image/x-webp image/svg+xml]
    unless allowed.include?(ct)
      errors.add(:logo, "must be PNG, JPG, GIF, WEBP o SVG")
    end
  end
end