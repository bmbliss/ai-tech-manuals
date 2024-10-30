class SectionsController < ApplicationController
  before_action :set_manual
  before_action :set_section, only: [:edit, :update, :destroy, :generate_content]

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
      @section.position = last_section ? last_section.position + 1 : 1
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

  def generate_content
    prompt = params[:prompt].presence || "Write a technical documentation section about"

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo-0125",
        messages: [
          { role: "system", content: "You are a technical writer creating documentation. Output in HTML format." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )

    # TODO - might need to do some parsing/sanitizing of the response

    if response["choices"]
      render json: { content: response["choices"][0]["message"]["content"] }
    else
      render json: { error: "Failed to generate content" }, status: :unprocessable_entity
    end
  end

  def search
    query = params[:query]
    return render json: { error: "Query required" }, status: :unprocessable_entity if query.blank?

    # Generate embedding for search query
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: query
      }
    )

    if response["data"]
      query_embedding = response["data"][0]["embedding"]
      
      # Search using vector similarity
      results = @manual.sections.collection.aggregate([
        {
          '$vectorSearch': {
            'queryVector': query_embedding,
            'path': 'embedding',
            'numCandidates': 100,
            'limit': 3,
            'index': 'manauls_sections_vector_index'
          },
        },
        {
          '$project': {
            '_id': 1,
            'manual_id': 1,
            'content': 1,
            "score" => { "$meta" => "vectorSearchScore" }
          }
        }
      ]).to_a

      render json: { results: results }
    else
      render json: { error: "Failed to generate embedding" }, status: :unprocessable_entity
    end
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