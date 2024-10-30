import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "sidebar", "results", "mainContent"]
  
  connect() {
    this.timeout = null
    this.currentSection = null
  }

  search(event) {
    clearTimeout(this.timeout)
    
    const query = this.queryTarget.value.trim()
    if (query.length < 3) {
      this.closeSidebar()
      return
    }
    
    this.timeout = setTimeout(() => this.performSearch(query), 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`/manuals/${this.getManualId()}/sections/search?query=${encodeURIComponent(query)}`)
      const data = await response.json()
      
      if (data.results && data.results.length > 0) {
        this.showResults(data.results)
      } else {
        this.showNoResults()
      }
    } catch (error) {
      console.error('Search error:', error)
      this.showError()
    }
  }

  showResults(results) {
    this.sidebarTarget.classList.remove('translate-x-full')
    this.mainContentTarget.classList.add('mr-96')
    
    this.resultsTarget.innerHTML = results.map(result => {
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = result.content
      const textContent = tempDiv.textContent || tempDiv.innerText
      const preview = textContent.substring(0, 200) + '...'
      const scorePercentage = Math.round(result.score * 100)
      
      return `
        <div class="border-b border-gray-200 pb-4 mb-4 last:border-b-0" data-section-id="section_${result._id}">
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

  showNoResults() {
    this.sidebarTarget.classList.remove('translate-x-full')
    this.mainContentTarget.classList.add('mr-96')
    
    this.resultsTarget.innerHTML = `
      <div class="text-center py-6 text-gray-500">
        <p>No matching sections found</p>
      </div>
    `
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="text-center py-6 text-red-500">
        <p>An error occurred while searching. Please try again.</p>
      </div>
    `
  }

  scrollToSection(event) {
    event.preventDefault()
    const sectionId = event.currentTarget.href.split('#')[1]
    
    // Remove previous highlight
    if (this.currentSection) {
      document.getElementById(this.currentSection).classList.remove('ring-2', 'ring-blue-500')
    }
    
    // Add highlight to new section
    const section = document.getElementById(sectionId)
    section.classList.add('ring-2', 'ring-blue-500')
    section.scrollIntoView({ behavior: 'smooth' })
    
    this.currentSection = sectionId
  }

  closeSidebar() {
    this.sidebarTarget.classList.add('translate-x-full')
    this.mainContentTarget.classList.remove('mr-96')
  }

  getManualId() {
    return window.location.pathname.split('/')[2]
  }
} 