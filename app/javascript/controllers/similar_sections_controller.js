import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "results", "spinner"]
  
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

  async performSearch(content) {
    try {
      const manualId = window.location.pathname.split('/')[2]
      const response = await fetch(
        `/manuals/${manualId}/sections/find_similar?${new URLSearchParams({
          content: content,
          manual_id: manualId
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
          <span class="text-sm font-medium text-gray-900">
            From: ${result.manual.title}
          </span>
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
    `).join('')
  }
} 