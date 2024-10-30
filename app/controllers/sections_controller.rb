class SectionsController < ApplicationController
  before_action :set_manual
  before_action :set_section, only: [:edit, :update, :destroy]

  def new
    @section = @manual.sections.build
    @prev_position = params[:prev_position]&.to_f
    @next_position = params[:next_position]&.to_f
  end

  def create
    @section = @manual.sections.build(section_params)
    
    # Calculate position if prev and next positions are provided
    if params[:prev_position].present? && params[:next_position].present?
      prev_pos = params[:prev_position].to_f
      next_pos = params[:next_position].to_f
      @section.position = Section.calculate_position(prev_pos, next_pos)
    else
      # Default to appending at the end
      last_section = @manual.sections.order(position: :desc).first
      @section.position = last_section ? last_section.position + 1000 : 1000
    end
    
    if @section.save
      redirect_to @manual, notice: 'Section was successfully added.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @section.update(section_params)
      redirect_to @manual, notice: 'Section was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @section.destroy
    redirect_to @manual, notice: 'Section was successfully removed.'
  end

  private

  def set_manual
    @manual = Manual.find(params[:manual_id])
  end

  def set_section
    @section = @manual.sections.find(params[:id])
  end

  def section_params
    params.require(:section).permit(:content)
  end
end 