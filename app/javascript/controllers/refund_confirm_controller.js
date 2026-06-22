// app/javascript/controllers/refund_confirm_controller.js
// Stimulus controller for the Process Refund confirmation modal
// Prevents accidental refunds by requiring an explicit two-step confirmation
// Uses global `bootstrap` object (loaded via <script> tag, not importmap)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "amount", "confirmationInput", "submitBtn"]
  static values = {
    amount: String,
    url: String
  }

  connect() {
    this.modalInstance = null
    // Reset confirmation when modal is hidden (e.g., cancel button)
    this.element.addEventListener("hidden.bs.modal", () => {
      if (this.hasConfirmationInputTarget) {
        this.confirmationInputTarget.value = ""
      }
      if (this.hasSubmitBtnTarget) {
        this.submitBtnTarget.disabled = true
      }
    })
  }

  // Called when "Process Refund" button is clicked
  show(event) {
    event.preventDefault()

    // Set the refund amount in the modal
    if (this.hasAmountTarget) {
      this.amountTarget.textContent = this.amountValue
    }

    // Reset the confirmation input
    if (this.hasConfirmationInputTarget) {
      this.confirmationInputTarget.value = ""
      this.confirmationInputTarget.disabled = false
    }

    // Disable submit button initially
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = true
    }

    // Show the modal
    const modalEl = this.modalTarget
    this.modalInstance = new bootstrap.Modal(modalEl, {
      backdrop: 'static',
      keyboard: false
    })
    this.modalInstance.show()
  }

  // Called when user types in the confirmation input
  checkConfirmation() {
    if (!this.hasConfirmationInputTarget || !this.hasSubmitBtnTarget) return

    const input = this.confirmationInputTarget.value.trim().toLowerCase()
    this.submitBtnTarget.disabled = (input !== "refund")
  }

  // Called when the confirm button is clicked
  confirm(event) {
    event.preventDefault()

    // Double-check the confirmation text
    if (!this.hasConfirmationInputTarget) return
    if (this.confirmationInputTarget.value.trim().toLowerCase() !== "refund") return

    // Hide the modal
    if (this.modalInstance) {
      this.modalInstance.hide()
    }

    // Clean up modal backdrop artifacts
    document.querySelectorAll('.modal-backdrop').forEach(b => b.remove())
    document.body.classList.remove('modal-open')
    document.body.style.removeProperty('overflow')
    document.body.style.removeProperty('padding-right')

    // Find the form and submit it
    const form = this.element.querySelector("form")
    if (form) {
      setTimeout(() => {
        // Disable Turbo for this form to prevent it from intercepting
        form.dataset.turbo = "false"
        form.submit()
      }, 200)
    }
  }

  disconnect() {
    if (this.modalInstance) {
      this.modalInstance.dispose()
      this.modalInstance = null
    }
  }
}
