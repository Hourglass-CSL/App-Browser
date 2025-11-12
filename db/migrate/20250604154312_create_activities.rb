class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.string :title
      t.string :location
      t.text :description
      t.string :day_of_week
      t.time :open_time
      t.time :closed_time

      t.timestamps
    end
  end
end
