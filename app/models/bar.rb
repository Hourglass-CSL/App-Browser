class Bar < ApplicationRecord
  include HasDayOfWeek
  attr_accessor :pending_logo_key
  has_one_attached :logo
 has_many_attached :menu_file   
  has_many_attached :menu_file_es 

  validate :logo_file_type
  validate :menu_file_types
  validates :logo, presence: true, unless: :logo_will_be_attached_async?
  validates :open_time, :closed_time,  :bar_type, presence: true
   validates :bar_name, :location, :ubicacion, presence: true, length: { maximum: 32 }
  validate :day_of_week_must_have_value

  after_create_commit  :broadcast_create_if_today
  after_update_commit  :broadcast_update_for_today
  after_destroy_commit :broadcast_remove_from_list

  def menu_attachments_for(locale = I18n.locale)
    if locale.to_sym == :es
      menu_file_es.attachments
    else
      menu_file.attachments
    end
  end


    private

  def logo_will_be_attached_async?
    pending_logo_key.present?
  end



  def bars_stream = "bars"

  # --- Broadcasts -------------------------------------------------------------

  def broadcast_create_if_today
    return unless for_today? # ← clave: solo si aplica hoy
    broadcast_append_to bars_stream,
      target:  bars_stream,
      partial: "bars/bar_card",
      locals:  { bar: self }
  end

  def broadcast_update_for_today
    id = ActionView::RecordIdentifier.dom_id(self)

    if saved_change_to_day_of_week?
      before, after = saved_change_to_day_of_week
      was_today = includes_today?(before)
      is_today  = includes_today?(after)

      case [was_today, is_today]
      when [false, true]
        # ahora sí es hoy → aparecer
        broadcast_append_to bars_stream,
          target:  bars_stream,
          partial: "bars/bar_card",
          locals:  { bar: self }
      when [true, false]
        # dejó de ser hoy → desaparecer
        broadcast_remove_to bars_stream, target: id
      when [true, true]
        # sigue siendo hoy → actualizar tarjeta
        broadcast_replace_to bars_stream,
          target:  id,
          partial: "bars/bar_card",
          locals:  { bar: self }
      else
        # [false, false] → no hacer nada
      end

      return
    end

    # Actualizaciones normales (sin cambiar day_of_week)
    if for_today?
      broadcast_replace_to bars_stream,
        target:  id,
        partial: "bars/bar_card",
        locals:  { bar: self }
    else
      broadcast_remove_to bars_stream, target: id
    end
  end

  def broadcast_remove_from_list
    broadcast_remove_to bars_stream,
      target: ActionView::RecordIdentifier.dom_id(self)
  end

  # --- Validaciones/Helpers ---------------------------------------------------

  def logo_file_type
    return unless logo.attached?
    allowed = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml"]
    errors.add(:logo, "must be a PNG, JPG, GIF, Webp, or SVG") unless allowed.include?(logo.blob.content_type)
  end

  def menu_file_types
       allowed = %w[image/png image/jpeg image/gif image/webp image/svg+xml application/pdf]

    { menu_file: menu_file, menu_file_es: menu_file_es }.each do |field, files|
      next unless files.attached?
      files.each do |att|
        unless allowed.include?(att.blob.content_type)
          errors.add(field, "must be a PNG, JPG, GIF, Webp, SVG, or PDF")
        end
      end
    end
  end


  def day_of_week_must_have_value
    if day_of_week.blank? || day_of_week.reject(&:blank?).empty?
      errors.add(:day_of_week, :blank)
    end
  end
end