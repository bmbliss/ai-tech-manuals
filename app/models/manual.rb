class Manual < ApplicationRecord
  has_many :sections, -> { order(position: :asc) }, dependent: :destroy
  
  validates :title, presence: true
end
