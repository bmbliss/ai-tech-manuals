class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :embedding, type: Array
  field :position, type: Integer

  belongs_to :manual

  # We'll use this for RAG
  index({ embedding: "2dsphere" })
end 