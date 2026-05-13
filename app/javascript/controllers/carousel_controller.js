// app/javascript/controllers/carousel_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "prev", "next", "dot"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showSlide(this.indexValue)
  }

  next() {
    this.indexValue = (this.indexValue + 1) % this.slideTargets.length
    this.showSlide(this.indexValue)
  }

  prev() {
    this.indexValue = (this.indexValue - 1 + this.slideTargets.length) % this.slideTargets.length
    this.showSlide(this.indexValue)
  }

  goTo(event) {
    const idx = parseInt(event.currentTarget.dataset.index)
    this.indexValue = idx
    this.showSlide(idx)
  }

  showSlide(idx) {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("active", i === idx)
    })
    if (this.dotTargets) {
      this.dotTargets.forEach((dot, i) => {
        dot.classList.toggle("active", i === idx)
      })
    }
  }
}
