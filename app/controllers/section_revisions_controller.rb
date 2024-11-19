class SectionRevisionsController < ApplicationController
  before_action :set_manual
  before_action :set_section
  before_action :set_revision, except: [:index, :create]

  def index
    @revisions = @section.revisions.includes(:created_by)
      .order(created_at: :desc)
  end

  def show
    @diff = @revision.generate_diff
    @comments = @revision.comments.includes(:user).order(created_at: :desc)
  end

  def approve
    if @revision.has_conflicts?
      redirect_to [@manual, @section, @revision], 
        alert: 'Cannot approve - this revision has conflicts with the current version.'
      return
    end

    ActiveRecord::Base.transaction do
      # Update the section with the new content
      @section.update!(
        content: @revision.content,
        position: @revision.position || @section.position,
        version_number: @section.version_number + 1,
        latest_revision_id: @revision.id
      )

      @revision.update!(status: 'approved')
    end

    redirect_to manual_section_path(@manual, @section), 
      notice: 'Revision approved and changes applied.'
  end

  def reject
    @revision.update!(status: 'rejected')
    redirect_to [@manual, @section, @revision], 
      notice: 'Revision rejected.'
  end

  def comment
    @comment = @revision.comments.build(
      content: params[:content],
      user: current_user
    )

    if @comment.save
      redirect_to [@manual, @section, @revision], 
        notice: 'Comment added.'
    else
      redirect_to [@manual, @section, @revision], 
        alert: 'Failed to add comment.'
    end
  end

  def create
    @revision = @section.revisions.build(revision_params.merge(
      created_by: current_user,
      manual: @manual,
      change_type: 'update',
      status: 'pending'
    ))

    if @revision.save
      redirect_to manual_section_revision_path(@manual, @section, @revision),
        notice: 'Revision created and pending review.'
    else
      render 'sections/edit', status: :unprocessable_entity
    end
  end

  private

  def set_manual
    @manual = Manual.find(params[:manual_id])
  end

  def set_section
    @section = @manual.sections.find(params[:section_id])
  end

  def set_revision
    @revision = @section.revisions.find(params[:id])
  end

  def revision_params
    params.require(:revision).permit(:content, :change_description)
  end
end 