class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :embedding, type: Array
  field :position, type: Integer

  belongs_to :manual

  validates :content, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  before_validation :set_position, on: :create

  # We'll use this for RAG
  index({ embedding: "2dsphere" })

  private

  def set_position
    self.position ||= manual.sections.count + 1
  end
end 