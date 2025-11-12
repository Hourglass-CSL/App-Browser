class CreateRestaurants < ActiveRecord::Migration[7.2]
  def change
    create_table :restaurants do |t|
      t.string :restaurant_name
      t.string :day_of_week
      t.time :open_time
      t.time :closed_time
      t.string :restaurant_type
      t.string :location
      t.string :dress_code

      t.timestamps
    end
  end
end
