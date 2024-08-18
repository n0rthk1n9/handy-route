//
//  CalendarManager.swift
//  Handy Route
//
//  Created by Jan Armbrust on 18.08.24.
//

import EventKit
import EventKitUI
import SwiftUI

enum CalendarError: Error {
  case noCalendarSelected
  case failedToCreateEndDate
  case accessDenied
}

@Observable
@MainActor
class CalendarManager {
  var eventStore = EKEventStore()
  var events: [EKEvent] = []
  var selectedCalendar: EKCalendar? {
    didSet {
      if let identifier = selectedCalendar?.calendarIdentifier {
        UserDefaults.standard.set(identifier, forKey: "SelectedCalendarIdentifier")
      } else {
        UserDefaults.standard.removeObject(forKey: "SelectedCalendarIdentifier")
      }
    }
  }

  var error: CalendarError?

  init(previewMode: Bool = false) {
    if previewMode {
      self.eventStore = EKEventStore(sources: [])
      self.selectedCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
      self.selectedCalendar?.title = "Preview Calendar"
      let event1 = EKEvent(eventStore: eventStore)
      event1.title = "Sample Event 1"
      event1.startDate = Date()
      event1.endDate = Date().addingTimeInterval(3600)
      let event2 = EKEvent(eventStore: eventStore)
      event2.title = "Sample Event 2"
      event2.startDate = Date().addingTimeInterval(86400)
      event2.endDate = Date().addingTimeInterval(90000)
      self.events = [event1, event2]
    } else {
      self.eventStore = EKEventStore()
      if let savedIdentifier = UserDefaults.standard.string(forKey: "SelectedCalendarIdentifier") {
        self.selectedCalendar = self.eventStore.calendar(withIdentifier: savedIdentifier)
      }
    }
  }

  func requestAccess() async throws {
    do {
      let granted = try await eventStore.requestFullAccessToEvents()
      if !granted {
        self.error = .accessDenied
        throw CalendarError.accessDenied
      }
    } catch {
      self.error = .accessDenied
      throw CalendarError.accessDenied
    }
  }

  func fetchEvents() async throws {
    guard let calendar = selectedCalendar else {
      self.error = .noCalendarSelected
      throw CalendarError.noCalendarSelected
    }

    let startDate = Date()
    guard let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) else {
      self.error = .failedToCreateEndDate
      throw CalendarError.failedToCreateEndDate
    }

    let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])

    self.events = self.eventStore.events(matching: predicate)
  }

  func selectCalendar(_ calendar: EKCalendar) {
    self.selectedCalendar = calendar
    self.error = nil
  }

  func clearError() {
    self.error = nil
  }
}
