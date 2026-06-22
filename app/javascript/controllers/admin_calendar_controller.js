// app/javascript/controllers/admin_calendar_controller.js
// Stimulus controller for the admin calendar management page
// Handles date selection, range highlighting, and bulk actions
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actionBar", "actionLabel", "singleDateForm", "bulkForm", "bulkStartDate", "bulkEndDate"]

  connect() {
    this.selectedStart = null
    this.selectedEnd = null
  }

  // Handle clicking a date cell
  toggleDateSelection(event) {
    const el = event.currentTarget
    const date = el.dataset.date
    const isBooked = el.dataset.status === 'booked'

    if (isBooked) return

    // Remove the today border when a user starts interacting
    this.deselectToday()

    // First click: set the start date
    if (!this.selectedStart) {
      this.clearSelection()
      this.selectedStart = date
      this.selectedEnd = null
      el.classList.add('day-selected')
    }
    // Second click on a different date: set the end date to form a range
    else if (this.selectedStart && !this.selectedEnd && date !== this.selectedStart) {
      this.selectedEnd = date
      // Order the dates
      if (this.selectedStart > this.selectedEnd) {
        [this.selectedStart, this.selectedEnd] = [this.selectedEnd, this.selectedStart]
      }
      this.highlightRange()
    }
    // Any other click (range already set, or same date clicked again): reset
    else {
      this.clearSelection()
      this.selectedStart = date
      this.selectedEnd = null
      el.classList.add('day-selected')
    }

    this.updateBulkActions()
  }

  deselectToday() {
    document.querySelectorAll('.calendar-day.day-today').forEach(el => {
      el.classList.remove('day-today')
    })
  }

  clearSelection() {
    document.querySelectorAll('.calendar-day.day-selected').forEach(el => {
      el.classList.remove('day-selected')
    })
  }

  highlightRange() {
    this.clearSelection()
    document.querySelectorAll('.calendar-day[data-date]').forEach(el => {
      const d = el.dataset.date
      if (d >= this.selectedStart && d <= this.selectedEnd && !d.startsWith('day-other-month')) {
        if (el.dataset.status !== 'booked') {
          el.classList.add('day-selected')
        }
      }
    })
  }

  updateBulkActions() {
    if (!this.hasActionBarTarget) return

    if (this.selectedStart && this.selectedEnd) {
      // Range selected — show bulk form, hide single form
      this.actionBarTarget.style.display = 'block'
      this.singleDateFormTarget.style.display = 'none'
      this.bulkFormTarget.style.display = 'block'
      this.actionLabelTarget.textContent = 'Bulk action for selected range:'
      this.bulkStartDateTarget.value = this.selectedStart
      this.bulkEndDateTarget.value = this.selectedEnd
    } else if (this.selectedStart && !this.selectedEnd) {
      // Single date selected — show single form, hide bulk form
      this.actionBarTarget.style.display = 'block'
      this.singleDateFormTarget.style.display = 'block'
      this.bulkFormTarget.style.display = 'none'
      this.actionLabelTarget.textContent = 'Update selected date:'
      this.singleDateFormTarget.action = `/admin/calendar/${this.selectedStart}`
      // Set dropdown to opposite of current status
      this.setSingleDateDropdown(this.selectedStart)
    } else {
      this.actionBarTarget.style.display = 'none'
    }
  }

  // Set the single-date dropdown to the opposite of the clicked date's current status
  setSingleDateDropdown(date) {
    const dayEl = document.querySelector(`.calendar-day[data-date="${date}"]`)
    if (!dayEl) return
    const currentStatus = dayEl.dataset.status
    const select = this.singleDateFormTarget.querySelector('select[name="status"]')
    if (!select) return

    if (currentStatus === 'blocked') {
      select.value = 'available'
    } else {
      // Default to 'blocked' for available, pending, or any other status
      select.value = 'blocked'
    }
  }

  // Cancel selection
  cancelBulk() {
    this.clearSelection()
    this.selectedStart = null
    this.selectedEnd = null
    this.updateBulkActions()
    this.restoreTodayHighlight()
  }

  // Restore the today highlight on the current date
  restoreTodayHighlight() {
    const todayStr = new Date().toISOString().split('T')[0]
    document.querySelectorAll('.calendar-day[data-date]').forEach(el => {
      if (el.dataset.date === todayStr) {
        el.classList.add('day-today')
      }
    })
  }
}
