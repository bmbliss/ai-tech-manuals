class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :embedding, type: Array
  field :position, type: Float

  belongs_to :manual

  validates :content, presence: true
  validates :position, presence: true

  # Indexes
  index({ manual_id: 1 }) # For belongs_to relationship lookups
  index({ manual_id: 1, position: 1 }) # For ordered sections within a manual
  index({ embedding: "2dsphere" }) # For vector similarity search

  before_validation :set_position, on: :create
  before_save :generate_embedding, if: :content_changed?

  private

  # FIXME
  def set_position
    return if position.present?

    last_section = manual.sections.order(position: :desc).first
    prev_section = manual.sections.where(:position.lt => position).order(position: :desc).first
    next_section = manual.sections.where(:position.gt => position).order(position: :asc).first

    self.position = if last_section
                     last_section.position + 1
                   else
                     1
                   end
  end

  def self.calculate_position(prev_pos, next_pos)
    return (next_pos + prev_pos) / 2.0
  end

  def generate_embedding
    return unless content.present?
    
    Rails.logger.info "Generating embedding for section #{id}"

    # Strip HTML and decode entities
    clean_content = ActionView::Base.full_sanitizer.sanitize(content)
    
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: clean_content
      }
    )

    if response["data"]
      self.set(embedding: response["data"][0]["embedding"])
    end
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
  end
end 