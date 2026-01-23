# app/models/spa.rb
class Spa < ApplicationRecord
  has_many_attached :menu_file
  has_many_attached :menu_file_es

after_update_commit -> {
  broadcast_replace_to(
    "settings",
    target: "spa_setting_#{id}",
    partial: "spas/spa",
    locals: { spa: self }
  )
}

  validates :spa_name, presence: true
  validate :menu_file_types

  # return the has_many_attached association (so attached? works)
  def menu_files_for(locale = I18n.locale)
    locale.to_sym == :es ? menu_file_es : menu_file
  end

  private

  def normalized_content_type_for(blob)
    ct = blob.content_type.presence
    return ct if ct.present? && ct != "application/octet-stream"
    Marcel::MimeType.for(Pathname.new(blob.filename.to_s), name: blob.filename.to_s)
  end

  def menu_file_types
    allowed = %w[
      image/png image/jpeg image/gif image/webp image/x-webp image/svg+xml
      application/pdf
    ]

    { menu_file: menu_file, menu_file_es: menu_file_es }.each do |field, files|
      next unless files.attached?
      files.each do |att|
        ct = normalized_content_type_for(att.blob)
        errors.add(field, "must be PNG, JPG, GIF, WEBP, SVG o PDF") unless allowed.include?(ct)
      end
    end
  end
end
