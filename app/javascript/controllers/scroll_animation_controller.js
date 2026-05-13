// app/javascript/controllers/scroll_animation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observe()
  }

  observe() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible')
          observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.1 })

    document.querySelectorAll('[data-animation]').forEach(el => observer.observe(el))
  }
}
