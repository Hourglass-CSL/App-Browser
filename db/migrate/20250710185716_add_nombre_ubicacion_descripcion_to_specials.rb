class AddNombreUbicacionDescripcionToSpecials < ActiveRecord::Migration[7.2]
  def change
    add_column :specials, :nombre, :string
    add_column :specials, :ubicacion, :string
    add_column :specials, :descripcion, :text
  end
end
