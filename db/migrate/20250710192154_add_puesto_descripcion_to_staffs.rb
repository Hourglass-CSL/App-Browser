class AddPuestoDescripcionToStaffs < ActiveRecord::Migration[7.2]
  def change
    add_column :staffs, :puesto, :string
    add_column :staffs, :descripcion, :text
  end
end
