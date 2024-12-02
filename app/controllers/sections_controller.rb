class SectionsController < ApplicationController
  before_action :set_manual
  before_action :set_section, except: [:new, :create]

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
    # Instead of editing directly, we'll create a new revision
    @revision = @section.revisions.build(
      content: @section.content,
      base_content: @section.content,
      base_version: @section.version_number,
      manual: @manual
    )
  end

  def update
    # Create a new revision instead of updating directly
    @revision = @section.revisions.build(revision_params.merge(
      change_type: 'update',
      created_by: current_user,
      manual: @manual
    ))

    if @revision.save
      redirect_to manual_section_revision_path(@manual, @section, @revision), 
        notice: 'Revision created and pending review.'
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

  def suggest_edits
    content = params[:content]
    similar_sections = params[:similar_sections]

    prompt = <<~PROMPT
      I have a technical documentation section and some similar sections from other manuals. 
      Please analyze the current content and the similar sections, then suggest improvements 
      to make the language and terminology more consistent with the similar sections while 
      maintaining the original meaning.

      Current content:
      #{content}

      Similar sections:
      #{similar_sections.map { |s| "#{s[:content]} (#{s[:similarity]}% similar)" }.join("\n\n")}

      Please provide an improved version of the current content that:
      1. Aligns terminology with similar sections
      2. Maintains the same meaning and structure
      3. Keeps any unique information from the original
      4. Uses consistent formatting
    PROMPT

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo-0125",
        messages: [
          { role: "system", content: "You are a technical documentation expert focused on maintaining consistency across documentation." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )

    if response.dig("choices", 0, "message", "content")
      render json: { suggestion: response["choices"][0]["message"]["content"] }
    else
      render json: { error: "Failed to generate suggestion" }, status: :unprocessable_entity
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

  def revision_params
    params.require(:revision).permit(:content, :change_description)
  end
end 