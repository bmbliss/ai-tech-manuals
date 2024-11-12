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
  
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: query
      }
    )
  
    if response["data"]
      query_embedding = response["data"][0]["embedding"]
      
      # Much cleaner with neighbor!
      results = @manual.sections.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(3)

      # FIXME - hack to exclude the embedding from the results
      res = results.map { |result| result.attributes.except("embedding") }

      render json: { results: res }
    else
      render json: { error: "Failed to generate embedding" }, status: :unprocessable_entity
    end
  end

  def summarize
    query = params[:query]
    results = params[:results]

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo-0125",
        messages: [
          { 
            role: "system", 
            content: "You are a helpful assistant that summarizes search results and answers questions based on the provided context. Keep your responses concise and focused."
          },
          { 
            role: "user", 
            content: "Question: #{query}\n\nContext:\n#{results.join("\n\n")}\n\nPlease provide a brief summary answering the question based on these search results. If you cannot answer the question based on the context provided, say so. Do not include any other information."
          }
        ],
        temperature: 0.7
      }
    )

    if response["choices"]
      render json: { summary: response["choices"][0]["message"]["content"] }
    else
      render json: { error: "Failed to generate summary" }, status: :unprocessable_entity
    end
  end

  def find_similar
    section = Section.find(params[:id]) if params[:id].present?
    query_text = section&.content || params[:content]
    return render json: { error: "No content provided" }, status: :unprocessable_entity if query_text.blank?

    # Get embedding for the query text
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: ActionView::Base.full_sanitizer.sanitize(query_text)
      }
    )

    if response["data"]
      query_embedding = response["data"][0]["embedding"]
      
      # Find similar sections across other manuals
      similar_sections = Section
        .where.not(manual_id: params[:manual_id])
        .where.not(embedding: nil)
        .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
        .limit(5)
        .includes(:manual)
      
      results = similar_sections.map do |s|
        {
          id: s.id,
          content: s.content,
          manual: {
            id: s.manual.id,
            title: s.manual.title
          },
          similarity_score: (1 - s.neighbor_distance/2) * 100
        }
      end

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