class Section < ApplicationRecord
  belongs_to :manual
  has_many :revisions, class_name: 'SectionRevision', dependent: :destroy
  belongs_to :latest_revision, class_name: 'SectionRevision', optional: true
  
  validates :content, presence: true
  validates :position, presence: true
  validates :version_number, presence: true, numericality: { greater_than: 0 }

  # Neighbor configuration for vector similarity
  has_neighbors :embedding, dimensions: 1536

  before_validation :set_position, on: :create
  before_save :generate_embedding, if: :content_changed?

  def apply_revision(revision)
    return false if revision.has_conflicts?

    transaction do
      update!(
        content: revision.content,
        position: revision.position || position,
        version_number: version_number + 1,
        latest_revision: revision
      )

      revision.update!(status: 'approved')
    end
    true
  end

  def pending_revisions
    revisions.where(status: 'pending')
  end

  private

  def set_position
    return if position.present?
    last_section = manual.sections.order(position: :desc).first
    self.position = last_section ? last_section.position + 1 : 1
  end

  def self.calculate_position(prev_pos, next_pos)
    (prev_pos + next_pos) / 2.0
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
