class Staff < ApplicationRecord

  has_one_attached :profile_picture
  validates :position, :name, :puesto, 
              presence: true,
              length: { maximum: 32 }
  validates :bio, :descripcion,
              length: { maximum: 120 }           
  validate :profile_picture_type
  
 
 after_create_commit -> {
    broadcast_append_to(
      "staff_list",                    
      target:   "staff_members",       
      partial:  "staffs/staff_card",
      locals:   { staff: self }
    )
  }

  after_update_commit -> {
    broadcast_replace_to(
      "staff_list",
      target:   "staff_#{id}",
      partial:  "staffs/staff_card",
      locals:   { staff: self }
    )
  }

  after_destroy_commit -> {
    broadcast_remove_to(
      "staff_list",
      target:   "staff_#{id}"
    )
  }
 
  private

  def profile_picture_type
    return unless profile_picture.attached?
    allowed = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml"]
    unless allowed.include?(profile_picture.blob.content_type)
      errors.add(:profile_picture, "must be a PNG, JPG, GIF, Webp, or SVG")
    end
  end

 

end