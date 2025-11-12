module HasDayOfWeek
  extend ActiveSupport::Concern

  class_methods do
    # Nombre del día de hoy (en inglés) en la zona indicada
    def today_name(tz: Time.zone.tzinfo&.name || Time.zone.name || "UTC")
      Time.use_zone(tz) { Date::DAYNAMES[Date.current.wday] }
    end

    # Filtra por un día específico (en inglés). Case-insensitive.
    def for_weekday(weekday_en, tz: nil)
      normalized = weekday_en.to_s.downcase
      where(<<~SQL, normalized)
        day_of_week IS NULL
        OR cardinality(day_of_week) = 0
        OR EXISTS (
          SELECT 1
          FROM unnest(day_of_week) AS d(day)
          WHERE lower(d.day) = ?
        )
      SQL
    end

    # Filtra por el día de HOY en la zona indicada (default: Time.zone)
    def for_today(tz: Time.zone.tzinfo&.name || Time.zone.name || "UTC")
      for_weekday(today_name(tz: tz))
    end
  end

  # ---------- Métodos de instancia (para usar en callbacks/broadcast) ----------

  # ¿Este registro aplica para "hoy"?
  def for_today?(tz: Time.zone.tzinfo&.name || Time.zone.name || "UTC")
    self.class.for_today(tz: tz).where(id: id).exists?
  end

  # Dado un array de días (p. ej., old_value/new_value tras un cambio),
  # ¿incluye el día de hoy?
  def includes_today?(arr, tz: Time.zone.tzinfo&.name || Time.zone.name || "UTC")
    today = self.class.today_name(tz: tz).to_s.downcase
    Array(arr).map { |d| d.to_s.downcase }.include?(today)
  end
end