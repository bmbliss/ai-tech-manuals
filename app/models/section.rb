class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :embedding, type: Array
  field :position, type: Float

  belongs_to :manual

  validates :content, presence: true
  validates :position, presence: true

  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?

    last_section = manual.sections.order(position: :desc).first
    prev_section = manual.sections.where(:position.lt => position).order(position: :desc).first
    next_section = manual.sections.where(:position.gt => position).order(position: :asc).first

    self.position = if last_section
                     last_section.position + 1000
                   else
                     1000
                   end
  end

  def self.calculate_position(prev_pos, next_pos)
    return (next_pos + prev_pos) / 2.0
  end
end 