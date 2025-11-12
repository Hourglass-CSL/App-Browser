class AddLocationToSpecials < ActiveRecord::Migration[7.2]
  def change
    add_column :specials, :location, :string
  end
end
