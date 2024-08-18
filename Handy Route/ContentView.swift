//
//  ContentView.swift
//  Handy Route
//
//  Created by Jan Armbrust on 13.08.24.
//

import EventKit
import SwiftUI

@MainActor
struct ContentView: View {
  @State private var calendarManager = CalendarManager()
  @State private var showingCalendarChooser = false
  @State private var showingError = false
  @State private var isLoading = false
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    NavigationView {
      List {
        Section {
          Button(self.calendarManager.selectedCalendar?.title ?? "Select Calendar") {
            self.showingCalendarChooser = true
          }
        }

        Section {
          if self.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, alignment: .center)
          } else if self.calendarManager.events.isEmpty {
            Text("No events found")
              .foregroundColor(.secondary)
          } else {
            ForEach(self.calendarManager.events, id: \.eventIdentifier) { event in
              VStack(alignment: .leading) {
                Text(event.title)
                  .font(.headline)
                Text(self.formatDate(event.startDate))
                  .font(.subheadline)
              }
            }
          }
        }
      }
      .navigationTitle("Appointments")
      .sheet(isPresented: self.$showingCalendarChooser) {
        CalendarChooserView(calendarManager: self.$calendarManager)
      }
      .alert(isPresented: self.$showingError) {
        Alert(title: Text("Error"), message: Text(self.errorMessage), dismissButton: .default(Text("OK")) {
          self.calendarManager.clearError()
        })
      }
      .task {
        await self.requestCalendarAccess()
      }
      .onChange(of: self.calendarManager.selectedCalendar) { _, _ in
        Task {
          await self.fetchEvents()
        }
      }
      .refreshable {
        await self.fetchEvents()
      }
      .onChange(of: self.scenePhase) { _, newPhase in
        if newPhase == .active {
          Task {
            await self.fetchEvents()
          }
        }
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private var errorMessage: String {
    switch self.calendarManager.error {
    case .noCalendarSelected:
      return "Please select a calendar."
    case .failedToCreateEndDate:
      return "Failed to create end date for event fetch."
    case .accessDenied:
      return "Calendar access was denied. Please grant access in Settings."
    case .none:
      return "An unknown error occurred."
    }
  }

  private func requestCalendarAccess() async {
    do {
      try await self.calendarManager.requestAccess()
      if self.calendarManager.selectedCalendar != nil {
        await self.fetchEvents()
      }
    } catch {
      self.showingError = true
    }
  }

  private func fetchEvents() async {
    guard self.calendarManager.selectedCalendar != nil else { return }
    self.isLoading = true
    do {
      try await self.calendarManager.fetchEvents()
    } catch {
      self.showingError = true
    }
    self.isLoading = false
  }
}

#Preview {
  ContentView()
    .environment(CalendarManager(previewMode: true))
}
