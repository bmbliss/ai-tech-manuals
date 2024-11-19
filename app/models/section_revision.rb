class SectionRevision < ApplicationRecord
  belongs_to :section, optional: true  # optional for new sections
  belongs_to :manual
  belongs_to :created_by, class_name: 'User'
  has_many :comments, class_name: 'RevisionComment', dependent: :destroy
  
  validates :content, presence: true
  validates :change_description, presence: true
  validates :change_type, inclusion: { in: %w[update create delete move] }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  
  before_create :set_base_version_and_content
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  
  def has_conflicts?
    return false if change_type == 'create'
    return false if base_version == section.version_number
    
    case change_type
    when 'update'
      base_content != section.content
    when 'move'
      base_position != section.position
    when 'delete'
      section.version_number != base_version
    else
      false
    end
  end

  def generate_diff
    Diffy::Diff.new(base_content || '', content || '').to_s(:html)
  end
  
  private
  
  def set_base_version_and_content
    return if change_type == 'create'
    
    self.base_version = section.version_number
    self.base_content = section.content
    self.base_position = section.position
  end
end 