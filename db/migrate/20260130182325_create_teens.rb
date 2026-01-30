class CreateTeens < ActiveRecord::Migration[7.2]
  def change
    create_table :teens do |t|
      t.string :teens_name

      t.timestamps
    end
  end
end
