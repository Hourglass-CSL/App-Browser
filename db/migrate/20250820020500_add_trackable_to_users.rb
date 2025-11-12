class AddTrackableToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :sign_in_count,      :integer,  null: false, default: 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at,    :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip,    :string
  end

  def down
    remove_column :users, :last_sign_in_ip
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_at
    remove_column :users, :current_sign_in_at
    remove_column :users, :sign_in_count
  end
end