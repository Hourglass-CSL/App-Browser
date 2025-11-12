class AddCuisineToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :cuisine_type, :string
  end
end
