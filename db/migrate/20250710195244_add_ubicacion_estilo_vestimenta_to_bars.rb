class AddUbicacionEstiloVestimentaToBars < ActiveRecord::Migration[7.2]
  def change
    add_column :bars, :ubicacion, :string
    add_column :bars, :estilo, :string
    add_column :bars, :vestimenta, :string
  end
end
