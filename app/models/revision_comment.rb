class RevisionComment < ApplicationRecord
  belongs_to :section_revision
  belongs_to :user

  validates :content, presence: true
  
  after_create :notify_revision_participants
  
  private
  
  def notify_revision_participants
    # TODO: Implement notification system for revision participants
    # This could notify the revision creator and previous commenters
  end
end 