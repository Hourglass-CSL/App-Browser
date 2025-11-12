class AddNombreToModuleTitles < ActiveRecord::Migration[7.2]
  def change
    add_column :module_titles, :nombre, :string
  end
end
