class DashboardController < ApplicationController
  def index
    @setting      = Setting.first_or_initialize
    @restaurant   = Restaurant.new
    @selected_day = params[:day]


    acts_scope = Activity
  .select(:id, :title, :nombre, :description, :descripcion, :open_time, :closed_time, :location, :ubicacion)
  .order(:open_time)
    specs_scope = Special.select(:id, :special_name, :nombre, :description, :descripcion, :open_time, :closed_time).order(:open_time)
    bars_scope  = Bar.select(:id, :bar_name, :open_time, :closed_time, :bar_type, :location, :ubicacion).order(:bar_name)
    rest_scope  = Restaurant.select(:id, :restaurant_name, :open_time, :closed_time, :restaurant_type, :location, :ubicacion, :meal_plan).order(:open_time)
    staffs_scope= Staff.select(:id, :name, :position, :puesto).order(:name)

    if @selected_day.present?
      acts_scope  = acts_scope.where("? = ANY(day_of_week)", @selected_day)
      specs_scope = specs_scope.where("? = ANY(day_of_week)", @selected_day)
      bars_scope  = bars_scope.where("? = ANY(day_of_week)", @selected_day)

      @breakfast_restaurants = rest_scope.where(meal_plan: %w[breakfast brunch])
                                         .where("? = ANY(day_of_week)", @selected_day)
                                         .load_async
      @lunch_restaurants     = rest_scope.where(meal_plan: %w[lunch])
                                         .where("? = ANY(day_of_week)", @selected_day)
                                         .load_async
      @dinner_restaurants    = rest_scope.where(meal_plan: %w[dinner])
                                         .where("? = ANY(day_of_week)", @selected_day)
                                         .load_async
    else
      @breakfast_restaurants = rest_scope.where(meal_plan: %w[breakfast brunch]).load_async
      @lunch_restaurants     = rest_scope.where(meal_plan: %w[lunch]).load_async
      @dinner_restaurants    = rest_scope.where(meal_plan: %w[dinner]).load_async
    end


    @activities = acts_scope.load_async
    @specials   = specs_scope.load_async
    @bars       = bars_scope.load_async
    @staffs     = staffs_scope.load_async
  end
end
