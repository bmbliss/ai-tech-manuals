import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "mainContent", "toggleButton"]

  connect() {
    this.updateSidebarState()
    
    // Handle resize events
    window.addEventListener('resize', () => this.updateSidebarState())
  }

  disconnect() {
    window.removeEventListener('resize', () => this.updateSidebarState())
  }

  toggle() {
    if (this.sidebarTarget.classList.contains('translate-x-0')) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.sidebarTarget.classList.remove('-translate-x-full')
    this.sidebarTarget.classList.add('translate-x-0')
    if (window.innerWidth >= 1024) { // lg breakpoint
      this.mainContentTarget.classList.add('ml-64')
    }
  }

  close() {
    this.sidebarTarget.classList.remove('translate-x-0')
    this.sidebarTarget.classList.add('-translate-x-full')
    this.mainContentTarget.classList.remove('ml-64')
  }

  updateSidebarState() {
    if (window.innerWidth >= 1024) {
      this.open()
    } else {
      this.close()
    }
  }
} 