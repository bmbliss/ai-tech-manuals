class Manual
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :content, type: String
  field :status, type: String, default: 'draft'
  
  has_many :sections, dependent: :destroy

  validates :title, presence: true
end 