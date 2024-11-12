import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "content", "prompt", "result", "generateButton", "applyButton"]
  static values = {
    manualId: String,
    sectionId: String
  }

  openModal() {
    this.modalTarget.classList.remove("hidden")
    // this.promptTarget.value = `Write a technical documentation section about...`
    this.promptTarget.value = `Write a section about the airline's drug and alcohol policy`
  }

  async generate(event) {
    event.preventDefault()
    this.generateButtonTarget.disabled = true
    this.generateButtonTarget.textContent = "Generating..."
    
    try {
      const response = await fetch(`/manuals/${this.manualIdValue}/sections/generate_content`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ 
          prompt: this.promptTarget.value,
          section_id: this.sectionIdValue
        })
      })

      const data = await response.json()
      if (data.content) {
        this.resultTarget.classList.remove("hidden")
        this.resultTarget.querySelector("div").innerHTML = data.content
        this.applyButtonTarget.classList.remove("hidden")
      } else {
        throw new Error(data.error || 'Failed to generate content')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to generate content. Please try again.')
    } finally {
      this.generateButtonTarget.disabled = false
      this.generateButtonTarget.textContent = "Generate"
    }
  }

  apply() {
    const content = this.resultTarget.querySelector("div").innerHTML
    tinymce.get(this.contentTarget.id).setContent(content)
    this.closeModal()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.resetModal()
  }

  resetModal() {
    this.promptTarget.value = ""
    this.resultTarget.classList.add("hidden")
    this.applyButtonTarget.classList.add("hidden")
  }
} 