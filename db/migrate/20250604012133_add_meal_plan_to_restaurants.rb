class AddMealPlanToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :meal_plan, :string
  end
end