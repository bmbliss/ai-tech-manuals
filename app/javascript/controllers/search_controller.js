import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "sidebar", "results", "spinner"]
  
  connect() {
    this.timeout = null
    this.currentSection = null
  }

  toggleSidebar() {
    this.sidebarTarget.classList.toggle('translate-x-full')
    if (!this.sidebarTarget.classList.contains('translate-x-full')) {
      this.queryTarget.focus()
    }
  }

  search(event) {
    clearTimeout(this.timeout)
    
    const query = this.queryTarget.value.trim()
    if (query.length < 3) {
      this.resultsTarget.innerHTML = ''
      return
    }
    
    this.spinnerTarget.classList.remove('hidden')
    this.timeout = setTimeout(() => this.performSearch(query), 500)
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
    } finally {
      this.spinnerTarget.classList.add('hidden')
    }
  }

  showResults(results) {
    this.sidebarTarget.classList.remove('translate-x-full')
    
    this.resultsTarget.innerHTML = `
      <div class="mb-6">
        <h3 class="text-sm font-medium text-gray-900 mb-2">AI Summary</h3>
        <div data-search-target="summary" class="prose prose-sm">
          <div class="animate-pulse flex space-x-4">
            <div class="flex-1 space-y-4 py-1">
              <div class="h-4 bg-gray-200 rounded w-3/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-200 rounded"></div>
                <div class="h-4 bg-gray-200 rounded w-5/6"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="border-t border-gray-200 pt-6">
        <h3 class="text-sm font-medium text-gray-900 mb-4">Matching Sections</h3>
        ${results.map(result => {
          const tempDiv = document.createElement('div')
          tempDiv.innerHTML = result.content
          const textContent = tempDiv.textContent || tempDiv.innerText
          const preview = textContent.substring(0, 200) + '...'
          const scorePercentage = Math.round((1 - result.neighbor_distance/2) * 100)
          
          return `
            <div class="border-b border-gray-200 pb-4 mb-4 last:border-b-0" data-section-id="section_${result.id}">
              <div class="flex items-center justify-between mb-2">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  scorePercentage > 80 ? 'bg-green-100 text-green-800' :
                  scorePercentage > 60 ? 'bg-yellow-100 text-yellow-800' :
                  'bg-red-100 text-red-800'
                }">
                  ${scorePercentage}% match
                </span>
                <a href="#section_${result.id}" 
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
        }).join('')}
      </div>
    `

    this.generateSummary(this.queryTarget.value, results)
  }

  async generateSummary(query, results) {
    try {
      const response = await fetch(`/manuals/${this.getManualId()}/sections/summarize`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ 
          query,
          results: results.map(r => r.content)
        })
      })
      
      const data = await response.json()
      if (data.summary) {
        const summaryEl = this.resultsTarget.querySelector('[data-search-target="summary"]')
        summaryEl.innerHTML = data.summary
      }
    } catch (error) {
      console.error('Summary error:', error)
    }
  }

  showNoResults() {
    this.sidebarTarget.classList.remove('translate-x-full')
    
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
  }

  getManualId() {
    return window.location.pathname.split('/')[2]
  }
} 