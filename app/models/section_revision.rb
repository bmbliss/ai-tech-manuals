class SectionRevision < ApplicationRecord
  belongs_to :section, optional: true  # optional for new sections
  belongs_to :manual
  belongs_to :created_by, class_name: 'User'
  has_many :comments, class_name: 'RevisionComment', dependent: :destroy
  
  validates :content, presence: true
  validates :change_description, presence: true
  validates :change_type, inclusion: { in: %w[update create delete move] }
  
  before_create :set_base_version_and_content
  
  def has_conflicts?
    return false if change_type == 'create'
    return false if base_version == section.version_number
    
    if change_type == 'update'
      base_content != section.content
    elsif change_type == 'move'
      base_position != section.position
    end
  end

  def generate_diff
    Diffy::Diff.new(base_content, content).to_s(:html)
  end
  
  private
  
  def set_base_version_and_content
    return if change_type == 'create'
    
    self.base_version = section.version_number
    self.base_content = section.content
    self.base_position = section.position
  end
end 