class Manual
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :status, type: String, default: 'draft'
  
  has_many :sections, dependent: :destroy, order: :position.asc

  validates :title, presence: true
end 