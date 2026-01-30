class DisplayController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
def index
   @spa = Spa.first_or_create!(spa_name: "Spa")
   @kids = Kid.first_or_create!(kids_name: "Kids Club")
   @teens = Teen.first_or_create!(Tens_name: "Teens Club")
   
    @staff_members = Staff.order(:name)
    .with_attached_profile_picture



    @breakfast_restaurants = Restaurant.where(meal_plan: ["breakfast", "brunch"])
      .for_today
      .order(:open_time)
      .with_attached_logo
      .order(
      Arel.sql("
        CASE
          WHEN open_time >= '05:00' THEN 0
          ELSE 1
        END,
        open_time
      ")
    )

    @lunch_restaurants = Restaurant.where(meal_plan: "lunch")
      .for_today
      .order(:open_time)
      .with_attached_logo
      .with_attached_menu_file
      .with_attached_menu_file_es
      .order(
      Arel.sql("
        CASE
          WHEN open_time >= '05:00' THEN 0
          ELSE 1
        END,
        open_time
      ")
    )

    @dinner_restaurants = Restaurant.where(meal_plan: ["dinner", "diner"])
      .for_today
      .order(:open_time)
      .with_attached_logo
      .with_attached_menu_file
      .with_attached_menu_file_es
      .order(
      Arel.sql("
        CASE
          WHEN open_time >= '05:00' THEN 0
          ELSE 1
        END,
        open_time
      ")
    )

    @bars = Bar.order(:bar_name)
      .for_today
      .with_attached_logo
      .with_attached_menu_file
      .with_attached_menu_file_es
      .order(
      Arel.sql("
        CASE
          WHEN open_time >= '05:00' THEN 0
          ELSE 1
        END,
        open_time
      ")
    )

    @activities = Activity
    .order(
      Arel.sql("
        CASE
          WHEN open_time >= '05:00' THEN 0
          ELSE 1
        END,
        open_time
      ")
    )
  .for_today
  .with_attached_cover_image


  
    @specials = Special.order(:open_time)
    .for_today
    .with_attached_cover_image


    # ─── WEATHER ───
    # 1) Use the correct lat/lon for Cabo San Lucas, BCS
    lat  = 22.8905    # Cabo San Lucas latitude
    lon  = -109.9167  # Cabo San Lucas longitude

    # 2) Use an IANA time zone that Rails recognizes for Cabo (Baja California Sur)
    zone = "America/Mazatlan"

    # 3) Make sure "imperial" is spelled correctly (for °F). If you want °C, use "metric".
    raw_data = WeatherService.fetch_forecast(
      lat:   lat,
      lon:   lon,
      units: "imperial"   # <─ use "metric" for °C, or "imperial" for °F
    )

    # 4) Pull out city name & the array of 3-hour forecasts
    @city_name     = raw_data.dig("city", "name") || "Desconocida"
    @forecast_list = raw_data["list"] || []

    # 5) Convert each forecast’s UTC timestamp into the desired time zone
    @forecast_entries = @forecast_list.map do |entry|
      # entry["dt"] is a UNIX timestamp (seconds since epoch, UTC)
      utc_time   = Time.at(entry["dt"]).utc
      local_time = utc_time.in_time_zone(zone)

      {
        time:        local_time,
        temp:        entry.dig("main", "temp"),             # e.g. 78.2  (°F if imperial)
        description: entry.dig("weather", 0, "description"),# e.g. "clear sky"
        icon_code:   entry.dig("weather", 0, "icon"),       # e.g. "01d"
        humidity:    entry.dig("main", "humidity"),         # e.g. 65
        wind_speed:  entry.dig("wind", "speed") ,            # e.g. 3.2 (m/s if metric, mph if imperial)
        min:         entry.dig("main", "temp_min"),
        max:         entry.dig("main", "temp_max")
      }
    end

    # (Optional) Only keep the next(~24 hours at 3-hour steps) intervals:
    @forecast_entries = @forecast_entries.first(1)
  end
end