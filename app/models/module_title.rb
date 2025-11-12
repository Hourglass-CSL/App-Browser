class ModuleTitle < ApplicationRecord
 validates :nombre, :title, presence: true
  
    after_update_commit -> {
    broadcast_replace_later_to "module_title", target: "module_title", partial: "module_titles/title", locals: { module_title: self }
  }
end
