import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "modal", "results"]
  
  connect() {
    this.timeout = null
  }

  search(event) {
    clearTimeout(this.timeout)
    
    const query = this.queryTarget.value.trim()
    if (query.length < 3) return
    
    this.timeout = setTimeout(() => this.performSearch(query), 300)
  }

  async performSearch(query) {
    const response = await fetch(`/manuals/${this.getManualId()}/sections/search?query=${encodeURIComponent(query)}`)
    const data = await response.json()
    
    if (data.results) {
      this.showResults(data.results)
    }
  }

  showResults(results) {
    this.modalTarget.classList.remove('hidden')
    
    this.resultsTarget.innerHTML = results.map(result => {
      // Strip HTML tags for preview and truncate
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = result.content
      const textContent = tempDiv.textContent || tempDiv.innerText
      const preview = textContent.substring(0, 200) + '...'
      
      // Convert score to percentage
      const scorePercentage = Math.round(result.score * 100)
      
      return `
        <div class="border-b border-gray-200 pb-4 last:border-b-0">
          <div class="flex items-center justify-between mb-2">
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
              ${scorePercentage}% match
            </span>
            <a href="#section_${result._id}" 
               data-action="search#scrollToSection"
               class="text-sm text-blue-600 hover:text-blue-900">
              Jump to section
            </a>
          </div>
          <div class="text-sm text-gray-600">
            ${preview}
          </div>
        </div>
      `
    }).join('')
  }

  scrollToSection(event) {
    event.preventDefault()
    const sectionId = event.currentTarget.href.split('#')[1]
    document.getElementById(sectionId).scrollIntoView({ behavior: 'smooth' })
    this.closeModal()
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
  }

  getManualId() {
    return window.location.pathname.split('/')[2]
  }
} 