// Disables the submit button on click to prevent double-clicks
// while the Stripe checkout page is loading.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  submit(event) {
    const button = this.buttonTarget || this.element.querySelector("button, input[type='submit'], input[type='image']")

    if (!button || button.disabled) {
      event.preventDefault()
      return
    }

    // Disable instantly and update the button text
    button.disabled = true
    button.value = "Redirecting to payment..."
    button.style.opacity = "0.7"
    button.style.cursor = "not-allowed"
  }
}
