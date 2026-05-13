// app/javascript/controllers/lightbox_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "lightbox", "lightboxImg", "close"]

  connect() {
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.close()
    })
  }

  open(event) {
    const img = event.currentTarget
    this.lightboxTarget.classList.add("active")
    this.lightboxImgTarget.src = img.src
    this.lightboxImgTarget.alt = img.alt
    document.body.classList.add("lightbox-open")
  }

  close() {
    this.lightboxTarget.classList.remove("active")
    document.body.classList.remove("lightbox-open")
  }
}
