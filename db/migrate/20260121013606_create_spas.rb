class CreateSpas < ActiveRecord::Migration[7.2]
  def change
    create_table :spas do |t|
      t.string :spa_name

      t.timestamps
    end
  end
end
