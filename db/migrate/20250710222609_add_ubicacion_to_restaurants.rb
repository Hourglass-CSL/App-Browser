class AddUbicacionToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :ubicacion, :string
  end
end
