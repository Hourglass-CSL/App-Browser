class RecreateDayOfWeekAsArrayInRestaurants < ActiveRecord::Migration[7.2]
  def up
    # remove the old single-string column
    remove_column :restaurants, :day_of_week, :string

    # add a brand-new Postgres string[] column
    add_column :restaurants,
               :day_of_week,
               :string,
               array:   true,
               default: [],
               null:    false
  end

  def down
    # revert: drop the array column
    remove_column :restaurants, :day_of_week, :string, array: true

    # then add back the old string column
    add_column    :restaurants, :day_of_week, :string
  end
end