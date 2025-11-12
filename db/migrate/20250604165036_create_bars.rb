class CreateBars < ActiveRecord::Migration[7.2]
  def change
    create_table :bars do |t|
      t.string :bar_name
      t.string :day_of_week
      t.time :open_time
      t.time :closed_time
      t.string :bar_type
      t.string :location
      t.string :dress_code

      t.timestamps
    end
  end
end
