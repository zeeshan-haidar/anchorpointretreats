// app/javascript/controllers/inquiry_dates_controller.js
// Stimulus controller for the inquiry form date range pickers
// Disables dates that are already booked or blocked
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut"]

  connect() {
    this.bookedDatesSet = new Set()
    this.loadBookedDates()
  }

  async loadBookedDates() {
    try {
      const monthsToFetch = []
      const today = new Date()
      
      for (let i = 0; i < 12; i++) {
        const m = today.getMonth() + 1 + i
        const year = today.getFullYear() + Math.floor((m - 1) / 12)
        const month = ((m - 1) % 12) + 1
        monthsToFetch.push({ year, month })
      }

      const allBooked = []
      
      for (const { year, month } of monthsToFetch) {
        const response = await fetch(`/availability/calendar?year=${year}&month=${month}`)
        if (response.ok) {
          const data = await response.json()
          data.days.forEach(day => {
            if (day.status === "booked" || day.status === "blocked" || day.status === "maintenance") {
              allBooked.push(day.date)
              this.bookedDatesSet.add(day.date)
            }
          })
        }
      }

      this.initDatepickers(allBooked)
    } catch (error) {
      console.error("Failed to load booked dates:", error)
      this.initDatepickers([])
    }
  }

  // Check if any date in a range (checkIn to checkOut, exclusive) is booked
  rangeHasBookedDates(checkInStr, checkOutStr) {
    const checkIn = new Date(checkInStr + "T12:00:00")
    const checkOut = new Date(checkOutStr + "T12:00:00")

    for (let d = new Date(checkIn); d < checkOut; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().slice(0, 10)
      if (this.bookedDatesSet.has(dateStr)) {
        return true
      }
    }
    return false
  }

  initDatepickers(bookedDates) {
    const commonConfig = {
      minDate: "today",
      dateFormat: "Y-m-d",
      disable: bookedDates.map(d => d),
      // Add custom class to booked dates so we can style them differently from past dates
      onDayCreate: (dObj, dStr, fp, dayElem) => {
        const dateStr = flatpickr.formatDate(dayElem.dateObj, "Y-m-d")
        if (this.bookedDatesSet.has(dateStr)) {
          dayElem.classList.add("flatpickr-day--booked")
        }
      }
    }

    // Check-in datepicker
    if (this.hasCheckInTarget && typeof flatpickr !== "undefined") {
      this.checkInPicker = flatpickr(this.checkInTarget, {
        ...commonConfig,
        placeholder: "Select check-in date",
        onChange: (selectedDates, dateStr) => {
          this.updatePreferredDates()
          // Set check-out min date to day after check-in
          if (selectedDates.length > 0 && this.checkOutPicker) {
            this.checkOutPicker.set("minDate", flatpickr.formatDate(new Date(selectedDates[0].getTime() + 86400000), "Y-m-d"))
          }
        }
      })
    }

    // Check-out datepicker
    if (this.hasCheckOutTarget && typeof flatpickr !== "undefined") {
      this.checkOutPicker = flatpickr(this.checkOutTarget, {
        ...commonConfig,
        placeholder: "Select check-out date",
        onChange: (selectedDates, dateStr) => {
          // Validate that the selected range doesn't contain booked dates
          const checkIn = this.checkInTarget.value
          const checkOut = dateStr

          if (checkIn && checkOut && this.rangeHasBookedDates(checkIn, checkOut)) {
            alert("Sorry, this date range includes dates that are already booked or unavailable. Please select a different range.")
            this.checkOutPicker.clear()
            return
          }

          this.updatePreferredDates()
        }
      })
    }
  }

  updatePreferredDates() {
    const checkIn = this.checkInTarget.value
    const checkOut = this.checkOutTarget.value

    // Find the preferred_dates field in the form
    const preferredDatesField = document.querySelector("#inquiry_preferred_dates")
    if (!preferredDatesField) return

    if (checkIn && checkOut) {
      const formatDisplay = (dateStr) => {
        const d = new Date(dateStr + "T12:00:00")
        return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
      }
      preferredDatesField.value = `${formatDisplay(checkIn)} — ${formatDisplay(checkOut)}`
      preferredDatesField.placeholder = "Dates selected above"
    } else if (checkIn) {
      preferredDatesField.value = `From ${new Date(checkIn + "T12:00:00").toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}...`
    } else {
      preferredDatesField.value = ""
    }
  }
}
