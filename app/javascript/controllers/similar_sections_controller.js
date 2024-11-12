import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "results", "spinner"]
  static values = {
    manualId: String
  }

  async findSimilar(event) {
    event.preventDefault()
    const content = tinymce.get(this.element.querySelector('textarea').id).getContent()
    if (content.length < 50) {
      alert('Please add more content before searching for similar sections')
      return
    }
    
    this.spinnerTarget.classList.remove('hidden')
    this.performSearch(content)
  }

  async suggestEdits(event) {
    event.preventDefault()
    const button = event.currentTarget
    button.disabled = true
    
    const content = tinymce.get(this.element.querySelector('textarea').id).getContent()
    const similarSections = this.getSelectedSections()
    
    try {
      const response = await fetch(`/manuals/${this.manualIdValue}/sections/suggest_edits`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ 
          content: content,
          similar_sections: similarSections
        })
      })
      
      const data = await response.json()
      if (data.suggestion) {
        tinymce.get(this.element.querySelector('textarea').id).setContent(data.suggestion)
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to generate suggestions. Please try again.')
    } finally {
      button.disabled = false
    }
  }

  getSelectedSections() {
    return Array.from(this.element.querySelectorAll('input[name="similar_sections[]"]:checked'))
      .map(checkbox => ({
        content: checkbox.dataset.content,
        similarity: checkbox.dataset.similarity
      }))
  }

  async performSearch(content) {
    try {
      const response = await fetch(
        `/manuals/${this.manualIdValue}/sections/find_similar?${new URLSearchParams({
          content: content,
          manual_id: this.manualIdValue
        })}`
      )
      
      const data = await response.json()
      if (data.results) {
        this.showResults(data.results)
      }
    } catch (error) {
      console.error('Error:', error)
    } finally {
      this.spinnerTarget.classList.add('hidden')
    }
  }

  showResults(results) {
    if (results.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-gray-500">No similar sections found</p>'
      return
    }

    this.resultsTarget.innerHTML = results.map(result => `
      <div class="border-b border-gray-200 pb-4 mb-4 last:border-b-0">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center">
            <input type="checkbox" 
                   name="similar_sections[]" 
                   value="${result.id}"
                   data-content="${encodeURIComponent(result.content)}"
                   data-similarity="${result.similarity_score}"
                   class="h-4 w-4 text-blue-600 rounded border-gray-300">
            <span class="ml-2 text-sm font-medium text-gray-900">
              From: ${result.manual.title}
            </span>
          </div>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
            result.similarity_score > 80 ? 'bg-green-100 text-green-800' :
            result.similarity_score > 60 ? 'bg-yellow-100 text-yellow-800' :
            'bg-red-100 text-red-800'
          }">
            ${Math.round(result.similarity_score)}% similar
          </span>
        </div>
        <div class="prose prose-sm max-w-none">
          ${result.content}
        </div>
      </div>
    `).join('') + `
      <div class="mt-4">
        <button type="button"
                data-action="similar-sections#suggestEdits"
                class="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 20 20" fill="currentColor">
            <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
          </svg>
          Suggest Edits Based on Selected
        </button>
      </div>
    `
  }
} 