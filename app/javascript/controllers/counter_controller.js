// app/javascript/controllers/counter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.intersect()
  }

  intersect() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animate()
          observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.5 })

    observer.observe(this.element)
  }

  animate() {
    const counters = this.element.querySelectorAll(".counter")
    counters.forEach(counter => {
      const target = parseFloat(counter.dataset.count)
      const duration = 2000
      const isDecimal = target % 1 !== 0
      const step = target / (duration / 16)
      let current = 0

      const update = () => {
        current += step
        if (current >= target) {
          counter.textContent = isDecimal ? target.toFixed(1) : Math.round(target)
          return
        }
        counter.textContent = isDecimal ? current.toFixed(1) : Math.round(current)
        requestAnimationFrame(update)
      }
      requestAnimationFrame(update)
    })
  }
}
