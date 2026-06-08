// app/javascript/controllers/availability_calendar_controller.js
// Stimulus controller for the availability calendar on /availability page
// Handles month navigation, date selection, and pricing preview
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calendarGrid", "monthLabel", "checkInDisplay", "checkOutDisplay",
    "guestSelect", "pricingSummary", "bookNowBtn"
  ]

  static values = {
    propertyId: Number,
    currentMonth: Number,
    currentYear: Number,
    minNights: { type: Number, default: 2 },
    maxNights: { type: Number, default: 30 },
    maxGuests: { type: Number, default: 4 }
  }

  connect() {
    this.selectedCheckIn = null
    this.selectedCheckOut = null
    this.monthData = {}
    this.isLoading = false

    this.month = this.currentMonthValue || new Date().getMonth() + 1
    this.year = this.currentYearValue || new Date().getFullYear()

    // First load the month, then check for URL params after rendering
    this.loadMonth(this.year, this.month)
  }

  // Load availability data for a given month/year
  async loadMonth(year, month) {
    if (this.isLoading) return
    this.isLoading = true

    try {
      const response = await fetch(`/availability/calendar?year=${year}&month=${month}`)
      if (!response.ok) throw new Error("Failed to load calendar data")

      const data = await response.json()
      this.monthData = data
      this.renderCalendar(data)
      // Apply URL params if coming back from booking page (only on initial load)
      this.applyUrlSelections()
    } catch (error) {
      console.error("Calendar load error:", error)
      this.calendarGridTarget.innerHTML = `
        <div class="col-12 text-center py-5">
          <p class="text-danger">Unable to load calendar. Please try again.</p>
        </div>
      `
    } finally {
      this.isLoading = false
    }
  }

  // Render the calendar grid
  renderCalendar(data) {
    const { days, year, month } = data
    const firstDay = new Date(year, month - 1, 1).getDay()
    const daysInMonth = new Date(year, month, 0).getDate()

    this.monthLabelTarget.textContent = `${this.getMonthName(month)} ${year}`

    let html = ""

    // Empty cells for days before the 1st
    for (let i = 0; i < firstDay; i++) {
      html += '<div class="calendar-cell calendar-cell--empty"></div>'
    }

    // Day cells
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`
      const dayData = days.find(d => d.date === dateStr)
      const status = dayData ? dayData.status : "available"
      const isPast = dayData ? dayData.past : new Date(year, month - 1, day) < new Date()
      const isToday = this.isToday(year, month, day)

      let cssClass = "calendar-cell"
      if (isPast && status !== "booked") cssClass += " calendar-cell--past"
      else if (status === "available") cssClass += " calendar-cell--available"
      else if (status === "booked") cssClass += " calendar-cell--booked"
      else if (status === "blocked" || status === "maintenance") cssClass += " calendar-cell--blocked"

      if (isToday) cssClass += " calendar-cell--today"

      // Check if selected
      if (this.isSelectedDate(year, month, day)) {
        cssClass += " calendar-cell--selected"
      }

      // Check if in range
      if (this.isInRange(year, month, day)) {
        cssClass += " calendar-cell--in-range"
      }

      const isSelectable = !isPast && (status === "available")

      html += `<div class="${cssClass}" data-date="${dateStr}" data-status="${status}" data-selectable="${isSelectable}" data-action="click->availability-calendar#selectDate">
        <span class="calendar-day-number">${day}</span>
      </div>`
    }

    this.calendarGridTarget.innerHTML = html
  }

  // Handle date selection
  selectDate(event) {
    const cell = event.currentTarget
    if (cell.dataset.selectable !== "true") return

    const dateStr = cell.dataset.date
    const clickedDate = new Date(dateStr + "T12:00:00")

    // If no check-in selected or check-out is before check-in, set as check-in
    if (!this.selectedCheckIn || (this.selectedCheckIn && this.selectedCheckOut)) {
      this.selectedCheckIn = clickedDate
      this.selectedCheckOut = null
    } else if (clickedDate <= this.selectedCheckIn) {
      // Clicked before or on check-in, reset check-in
      this.selectedCheckIn = clickedDate
      this.selectedCheckOut = null
    } else {
      // Clicked after check-in, set as check-out
      this.selectedCheckOut = clickedDate
    }

    this.updateDateDisplays()
    this.renderCalendar(this.monthData)

    if (this.selectedCheckIn && this.selectedCheckOut) {
      this.updatePricing()
      this.updateBookNowLink()
    }
  }

  // Update the check-in/check-out display in the sidebar
  updateDateDisplays() {
    const formatDate = (date) => {
      if (!date) return "—"
      const options = { weekday: "short", month: "short", day: "numeric", year: "numeric" }
      return date.toLocaleDateString("en-US", options)
    }

    this.checkInDisplayTarget.textContent = formatDate(this.selectedCheckIn)
    this.checkOutDisplayTarget.textContent = formatDate(this.selectedCheckOut)
  }

  // Fetch and display pricing for selected range
  async updatePricing() {
    if (!this.selectedCheckIn || !this.selectedCheckOut) return

    const checkIn = this.formatDateParam(this.selectedCheckIn)
    const checkOut = this.formatDateParam(this.selectedCheckOut)
    const numGuests = this.guestSelectTarget.value

    try {
      const response = await fetch(`/availability/pricing?check_in=${checkIn}&check_out=${checkOut}&num_guests=${numGuests}`)
      if (!response.ok) throw new Error("Failed to load pricing")

      const data = await response.json()

      if (data.success || data.success === undefined) {
        this.renderPricingSummary(data)
      } else {
        this.pricingSummaryTarget.innerHTML = `<p class="text-danger">${data.error || "Unable to calculate pricing"}</p>`
      }
    } catch (error) {
      console.error("Pricing load error:", error)
      this.pricingSummaryTarget.innerHTML = '<p class="text-danger">Unable to calculate pricing</p>'
    }
  }

  // Render the pricing summary in the sidebar
  renderPricingSummary(data) {
    const formatPrice = (cents) => {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(cents / 100)
    }

    this.pricingSummaryTarget.innerHTML = `
      <div class="d-flex justify-content-between mb-2">
        <span>Nightly Rate</span>
        <span>${formatPrice(data.nightly_rate_cents)}</span>
      </div>
      <div class="d-flex justify-content-between mb-2">
        <span>Nights</span>
        <span>${data.num_nights}</span>
      </div>
      <hr>
      <div class="d-flex justify-content-between mb-2">
        <span>Subtotal</span>
        <span>${formatPrice(data.subtotal_cents)}</span>
      </div>
      <div class="d-flex justify-content-between mb-2">
        <span>Cleaning Fee</span>
        <span>${formatPrice(data.cleaning_fee_cents)}</span>
      </div>
      <div class="d-flex justify-content-between mb-2">
        <span>Taxes</span>
        <span>${formatPrice(data.taxes_cents)}</span>
      </div>
      <hr class="fw-bold">
      <div class="d-flex justify-content-between mb-2 fw-bold fs-5">
        <span>Total</span>
        <span>${formatPrice(data.total_cents)}</span>
      </div>
      <div class="d-flex justify-content-between text-muted small">
        <span>Deposit (25%)</span>
        <span>${formatPrice(data.deposit_amount_cents)}</span>
      </div>
    `
  }

  // Build the "Book Now" link
  updateBookNowLink() {
    const checkIn = this.formatDateParam(this.selectedCheckIn)
    const checkOut = this.formatDateParam(this.selectedCheckOut)
    const guests = this.guestSelectTarget.value
    const url = `/book?check_in=${checkIn}&check_out=${checkOut}&num_guests=${guests}`

    this.bookNowBtnTarget.href = url
    this.bookNowBtnTarget.classList.remove("disabled-link")
  }

  // Navigate to previous month
  previousMonth() {
    this.month--
    if (this.month < 1) {
      this.month = 12
      this.year--
    }
    this.loadMonth(this.year, this.month)
  }

  // Navigate to next month
  nextMonth() {
    this.month++
    if (this.month > 12) {
      this.month = 1
      this.year++
    }
    this.loadMonth(this.year, this.month)
  }

  // Helper: check if a date is today
  isToday(year, month, day) {
    const today = new Date()
    return year === today.getFullYear() &&
           month === today.getMonth() + 1 &&
           day === today.getDate()
  }

  // Helper: check if a date is currently selected
  isSelectedDate(year, month, day) {
    const checkDate = (date) => {
      if (!date) return false
      return date.getFullYear() === year &&
             date.getMonth() === month - 1 &&
             date.getDate() === day
    }
    return checkDate(this.selectedCheckIn) || checkDate(this.selectedCheckOut)
  }

  // Helper: check if a date is in the selected range
  isInRange(year, month, day) {
    if (!this.selectedCheckIn || !this.selectedCheckOut) return false
    const date = new Date(year, month - 1, day)
    return date > this.selectedCheckIn && date < this.selectedCheckOut
  }

  // Helper: format date as YYYY-MM-DD for URL params
  formatDateParam(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  // Apply pre-selected dates from URL params (from Go Back on booking page)
  applyUrlSelections() {
    // Only run once — if we already processed URL params, skip
    if (this._urlParamsApplied) return
    
    const params = new URLSearchParams(window.location.search)
    const checkIn = params.get('check_in')
    const checkOut = params.get('check_out')
    const numGuests = params.get('num_guests')

    if (checkIn && checkOut) {
      this.selectedCheckIn = new Date(checkIn + 'T12:00:00')
      this.selectedCheckOut = new Date(checkOut + 'T12:00:00')

      // Set guest count if provided
      if (numGuests && this.hasGuestSelectTarget) {
        this.guestSelectTarget.value = numGuests
      }

      // Re-render calendar to apply highlighted cells
      if (this.monthData && this.monthData.days) {
        this.renderCalendar(this.monthData)
      }

      this.updateDateDisplays()
      this.updatePricing()
      this.updateBookNowLink()
      
      this._urlParamsApplied = true
    }
  }

  // Helper: get month name
  getMonthName(num) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]
    return months[num - 1]
  }
}
