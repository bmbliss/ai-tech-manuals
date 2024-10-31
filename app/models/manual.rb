class Manual
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :status, type: String, default: 'draft'
  
  has_many :sections, dependent: :destroy, order: :position.asc

  validates :title, presence: true

  # Indexes
  index({ title: 1 })  # For title searches
  index({ status: 1 }) # For filtering by status
  index({ created_at: -1 }) # For sorting by creation date
end 