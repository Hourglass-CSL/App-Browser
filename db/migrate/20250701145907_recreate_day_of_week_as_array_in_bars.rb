class RecreateDayOfWeekAsArrayInBars < ActiveRecord::Migration[7.2]
  def up
    # 1️⃣ Remove the old single‐value column
    remove_column :bars, :day_of_week, :string

    # 2️⃣ Add a new Postgres string‐array column
    add_column :bars,
               :day_of_week,
               :string,
               array:   true,
               default: [],
               null:    false
  end

  def down
    # Revert back to a plain string column
    remove_column :bars, :day_of_week, :string, array: true
    add_column    :bars, :day_of_week, :string
  end
end
