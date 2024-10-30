class ManualsController < ApplicationController
  before_action :set_manual, only: [:show, :edit, :update, :destroy]

  def index
    @manuals = Manual.all
  end

  def show
    @sections = @manual.sections.order(position: :asc)
  end

  def new
    @manual = Manual.new
  end

  def create
    @manual = Manual.new(manual_params)
    
    if @manual.save
      redirect_to @manual, notice: 'Manual was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @manual.update(manual_params)
      redirect_to @manual, notice: 'Manual was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @manual.destroy
    redirect_to manuals_url, notice: 'Manual was successfully deleted.'
  end

  private

  def set_manual
    @manual = Manual.find(params[:id])
  end

  def manual_params
    params.require(:manual).permit(:title, :description)
  end
end 