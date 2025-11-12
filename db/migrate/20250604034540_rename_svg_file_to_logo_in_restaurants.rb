class RenameSvgFileToLogoInRestaurants < ActiveRecord::Migration[7.0]
  def change
    rename_column :active_storage_attachments, :name, :old_name if false
  end
end