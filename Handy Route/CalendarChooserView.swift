//
//  CalendarChooserView.swift
//  Handy Route
//
//  Created by Jan Armbrust on 18.08.24.
//

import EventKit
import EventKitUI
import SwiftUI

struct CalendarChooserView: UIViewControllerRepresentable {
  @Environment(\.dismiss) var dismiss
  @Binding var calendarManager: CalendarManager

  func makeUIViewController(context: Context) -> UINavigationController {
    let chooser = EKCalendarChooser(
      selectionStyle: .single,
      displayStyle: .allCalendars,
      entityType: .event,
      eventStore: calendarManager.eventStore
    )
    chooser.showsDoneButton = true
    chooser.showsCancelButton = true
    chooser.delegate = context.coordinator
    return UINavigationController(rootViewController: chooser)
  }

  func updateUIViewController(_: UINavigationController, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, EKCalendarChooserDelegate {
    var parent: CalendarChooserView

    init(_ parent: CalendarChooserView) {
      self.parent = parent
    }

    @MainActor
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
      if let selectedCalendar = calendarChooser.selectedCalendars.first {
        self.parent.calendarManager.selectCalendar(selectedCalendar)
      }
      self.parent.dismiss()
    }

    func calendarChooserDidCancel(_: EKCalendarChooser) {
      self.parent.dismiss()
    }
  }
}

#Preview {
  CalendarChooserView(calendarManager: .constant(CalendarManager(previewMode: true)))
}
