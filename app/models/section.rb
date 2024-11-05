class Section < ApplicationRecord
  belongs_to :manual
  
  validates :content, presence: true
  validates :position, presence: true

  # Neighbor configuration
  has_neighbors :embedding, dimensions: 1536  # For text-embedding-3-small
  
  before_validation :set_position, on: :create
  before_save :generate_embedding, if: :content_changed?
  
  private
  
  def set_position
    return if position.present?
    last_section = manual.sections.order(position: :desc).first
    self.position = last_section ? last_section.position + 1 : 1
  end

  def self.calculate_position(prev_pos, next_pos)
    return (next_pos + prev_pos) / 2.0
  end
  
  def generate_embedding
    return unless content.present?
    
    clean_content = ActionView::Base.full_sanitizer.sanitize(content)
    
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: clean_content
      }
    )
    
    if response["data"]
      self.embedding = response["data"][0]["embedding"]
    end
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
  end
end
