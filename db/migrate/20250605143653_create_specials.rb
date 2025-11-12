class CreateSpecials < ActiveRecord::Migration[7.2]
  def change
    create_table :specials do |t|
      t.string :title
      t.string :special_name
      t.string :day_of_week
      t.time :open_time
      t.time :closed_time
      t.text :description

      t.timestamps
    end
  end
end
