class AddNombreUbicacionDescripcionToActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :activities, :nombre, :string
    add_column :activities, :ubicacion, :string
    add_column :activities, :descripcion, :text
  end
end
