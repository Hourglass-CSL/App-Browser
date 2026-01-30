class CreateKids < ActiveRecord::Migration[7.2]
  def change
    create_table :kids do |t|
      t.string :kids_name

      t.timestamps
    end
  end
end
