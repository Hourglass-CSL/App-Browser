class SpecialModule < ApplicationRecord
  after_create_commit  -> { broadcast_append_to    "specials" }
  after_update_commit  -> { broadcast_replace_to   "specials" }
  after_destroy_commit -> { broadcast_remove_to    "specials" }

  validates :title, presence: true
end
