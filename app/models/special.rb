class Special < ApplicationRecord
  include HasDayOfWeek

  has_one_attached :cover_image
  validates :open_time, :closed_time, presence: true
  validates :nombre, :special_name, :ubicacion, :location,
            presence: true,
            length: { maximum: 32 }
  validates :description, :descripcion,
            length: { maximum: 120 }
  validate  :day_of_week_must_have_value
  validate  :cover_image_type

  # 🔄 Callbacks condicionados por “hoy”
  after_create_commit  :broadcast_create_if_today
  after_update_commit  :broadcast_update_for_today
  after_destroy_commit :broadcast_remove_from_list

 

  private

  # --- Streams/targets --------------------------------------------------------
  def specials_stream = "specials_list"
  def specials_target = "specials"
  def dom_target      = "special_#{id}"

  # --- Broadcasts -------------------------------------------------------------

  def broadcast_create_if_today
    return unless for_today? # ← clave: no se cuela si no es hoy
    broadcast_append_to(
      specials_stream,
      target:  specials_target,
      partial: "specials/special_card",
      locals:  { special: self }
    )
  end

  def broadcast_update_for_today
    if saved_change_to_day_of_week?
      before, after = saved_change_to_day_of_week
      was_today = includes_today?(before)
      is_today  = includes_today?(after)

      case [was_today, is_today]
      when [false, true]
        broadcast_append_to(
          specials_stream,
          target:  specials_target,
          partial: "specials/special_card",
          locals:  { special: self }
        )
      when [true, false]
        broadcast_remove_to(specials_stream, target: dom_target)
      when [true, true]
        broadcast_replace_to(
          specials_stream,
          target:  dom_target,
          partial: "specials/special_card",
          locals:  { special: self }
        )
      else
        # [false, false] → no hacer nada
      end

      return
    end

    # Actualizaciones normales (sin cambiar day_of_week)
    if for_today?
      broadcast_replace_to(
        specials_stream,
        target:  dom_target,
        partial: "specials/special_card",
        locals:  { special: self }
      )
    else
      broadcast_remove_to(specials_stream, target: dom_target)
    end
  end

  def broadcast_remove_from_list
    broadcast_remove_to(specials_stream, target: dom_target)
  end

  # --- Validaciones/archivos --------------------------------------------------

  def cover_image_type
    return unless cover_image.attached?
    allowed = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml"]
    errors.add(:cover_image, "must be a PNG, JPG, GIF, Webp, or SVG") unless allowed.include?(cover_image.blob.content_type)
  end

  def day_of_week_must_have_value
    if day_of_week.blank? || day_of_week.reject(&:blank?).empty?
      errors.add(:day_of_week, :blank)
    end
  end
end