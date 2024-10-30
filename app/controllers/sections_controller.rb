class SectionsController < ApplicationController
  before_action :set_manual
  before_action :set_section, only: [:edit, :update, :destroy]

  def new
    @section = @manual.sections.build(position: @manual.sections.count + 1)
  end

  def create
    @section = @manual.sections.build(section_params)
    
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
    params.require(:section).permit(:content, :position)
  end
end 