// app/javascript/controllers/lightbox_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modalImg"]

  open(event) {
    event.preventDefault()
    const link = event.currentTarget
    const img = link.querySelector("img")
    if (!img) return

    this.modalImgTarget.src = img.getAttribute("src")
    this.modalImgTarget.alt = img.getAttribute("alt")

    const modalEl = document.getElementById("galleryModal")
    const modal = bootstrap.Modal.getOrCreateInstance(modalEl)
    modal.show()
  }
}
