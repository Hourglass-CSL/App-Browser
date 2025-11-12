# app/services/weather_service.rb
class WeatherService
  include HTTParty
  base_uri "https://api.openweathermap.org/data/2.5"

  def self.fetch_forecast(lat:, lon:, units: "metric", cnt: nil)
    api_key = ENV["OPENWEATHER_API_KEY"].presence || Rails.application.credentials.openweather_api_key

    if api_key.blank?
      Rails.logger.error("[WeatherService] Missing OpenWeather API key (ENV or credentials)")
      return {}
    end

    query = {
      lat: lat,
      lon: lon,
      appid: api_key,
      units: units,
      lang: I18n.locale.to_s
    }
    query[:cnt] = cnt if cnt.present?

    resp = get("/forecast", query: query)
    if resp.success?
      resp.parsed_response
    else
      Rails.logger.error("[WeatherService] OpenWeatherMap error: #{resp.code} #{resp.message} - #{resp.body}")
      {}
    end
  end
end
