class Restaurant < ApplicationRecord
  include HasDayOfWeek

  has_one_attached :logo
  has_many_attached :menu_file   
  has_many_attached :menu_file_es 

  attr_accessor :pending_logo_key

  validate :logo_file_type
  validate :menu_file_types

  validates :logo, presence: true, unless: :logo_will_be_attached_async?
  validates :open_time, :closed_time, :meal_plan, :cuisine_type, :restaurant_type, presence: true
  validates :restaurant_name, :location, :ubicacion, presence: true, length: { maximum: 32 }
  validate  :day_of_week_must_have_value

  after_create_commit  :broadcast_prepend_to_sections
  after_update_commit  :broadcast_update_sections
  after_destroy_commit :broadcast_remove_from_sections


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


  def streams_for(plan)
    [].tap do |a|
      a << "breakfast_restaurants" if plan.in?(%w[breakfast brunch])
      a << "lunch_restaurants"     if plan == "lunch"
      a << "dinner_restaurants"    if plan.in?(%w[dinner diner])
    end
  end

  def broadcast_prepend_to_sections
    return unless for_today?

    streams_for(meal_plan).each do |stream|
      broadcast_prepend_to stream,
        target:  stream,
        partial: "restaurants/restaurant_card",
        locals:  { restaurant: self }
    end
  end

  def broadcast_remove_from_sections
    id = ActionView::RecordIdentifier.dom_id(self)
    streams_for(meal_plan).each do |stream|
      broadcast_remove_to stream, target: id
    end
  end

  def broadcast_update_sections
  id = ActionView::RecordIdentifier.dom_id(self)

  # 3A) Si cambió el meal_plan, mantenemos tu lógica actual
  if saved_change_to_meal_plan?
    old_plan, new_plan = saved_change_to_meal_plan
    old_streams = streams_for(old_plan)
    new_streams = streams_for(new_plan)

    # Quitar de streams que ya no aplican
    (old_streams - new_streams).each { |s| broadcast_remove_to s, target: id }

    # Agregar a streams nuevos SOLO si aplica hoy
    if for_today?
      (new_streams - old_streams).each do |s|
        broadcast_prepend_to s, target: s,
          partial: "restaurants/restaurant_card", locals: { restaurant: self }
      end

      (old_streams & new_streams).each do |s|
        broadcast_replace_to s, target: id,
          partial: "restaurants/restaurant_card", locals: { restaurant: self }
      end
    end

    return
  end

  # 3B) Si cambió day_of_week, decidimos aparecer/desaparecer
  if saved_change_to_day_of_week?
    before, after = saved_change_to_day_of_week
    was_today = includes_today?(before)
    is_today  = includes_today?(after)

    streams_for(meal_plan).each do |stream|
      case [was_today, is_today]
      when [false, true]
        # ahora sí es hoy → aparecer
        broadcast_prepend_to stream, target: stream,
          partial: "restaurants/restaurant_card", locals: { restaurant: self }
      when [true, false]
        # dejó de ser hoy → desaparecer
        broadcast_remove_to stream, target: id
      when [true, true]
        # sigue siendo hoy → actualizar
        broadcast_replace_to stream, target: id,
          partial: "restaurants/restaurant_card", locals: { restaurant: self }
      else
        # [false, false] → ni estaba ni está para hoy → no hacer nada
      end
    end

    return
  end

  # 3C) Actualizaciones normales (sin cambiar plan ni días)
  if for_today?
    streams_for(meal_plan).each do |stream|
      broadcast_replace_to stream, target: id,
        partial: "restaurants/restaurant_card", locals: { restaurant: self }
    end
  else
    # Si ya no aplica hoy (por otra razón), asegúrate de no verlo
    streams_for(meal_plan).each { |s| broadcast_remove_to s, target: id }
  end
end

  def logo_file_type
    return unless logo.attached?

    allowed = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml"]
    unless allowed.include?(logo.blob.content_type)
      errors.add(:logo, "must be a PNG, JPG, GIF, Webp, or SVG")
    end
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