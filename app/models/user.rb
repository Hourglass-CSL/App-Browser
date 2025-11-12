class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable, :trackable

  enum role: { admin: 0, user: 1, reader: 2 }

  validates :role, presence: true
  validates :name, presence: true
end