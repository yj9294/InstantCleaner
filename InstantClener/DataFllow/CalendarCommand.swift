//
//  CalendarCommand.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import EventKit

struct CalendarCommand: Command {
    func execute(in store: Store) {
        let calendar = Calendar.current
        
        var oneDayAgoComponents = DateComponents()
        oneDayAgoComponents.day = -1
        let oneDayAgo = calendar.date(byAdding: oneDayAgoComponents, to: Date())!
        
        var startTimeComponents = DateComponents()
        startTimeComponents.year = -3
        let startTime = calendar.date(byAdding: startTimeComponents, to: Date())!
        
        let predicate = store.state.calendarStore.predicateForEvents(withStart: startTime, end: oneDayAgo, calendars: nil)
        
        let events = store.state.calendarStore.events(matching: predicate)
        
        let sortArr = events.sorted { (model1, model2) -> Bool in
            if let date1 = model1.startDate,let date2 = model2.startDate {
                return date1.compare(date2) == .orderedDescending
            }
            return false
        }
        
        let array: [CalendarItem] = sortArr.map {
            CalendarItem(event: $0, date: $0.startDate.format(), title: $0.title ?? "New Event", content: "\($0.calendar.title):\($0.calendar.type == .subscription ? "subscription" : "iCloud")", isSelected: false)
        }
        
        let group = Dictionary(grouping: array) { event in
            return event.date
        }
        
        var tempDataArray: [[CalendarItem]] = []
        for item in group.values {
            tempDataArray.append(item)
        }
        
        let result = tempDataArray.sorted { (model1, model2) -> Bool in
            if let date1 = model1.first?.dateInt, let date2 = model2.first?.dateInt {
                return date1 > date2
            }
            return false
        }
        store.dispatch(.calendarStore(result))
    }
}


struct CalendarAllSelectCommand: Command {
    func execute(in store: Store) {
        let array: [[CalendarItem]] = store.state.calendar.calendars.map {
            $0.map {
                CalendarItem(event: $0.event, date: $0.date, title: $0.title, content: $0.content, isSelected: true)
            }
        }
        store.dispatch(.calendarStore(array))
    }
}

struct CalendarCancelCommand: Command {
    func execute(in store: Store) {
        let array: [[CalendarItem]] = store.state.calendar.calendars.map {
            $0.map {
                CalendarItem(event: $0.event, date: $0.date, title: $0.title, content: $0.content, isSelected: false)
            }
        }
        store.dispatch(.calendarStore(array))
    }
}

struct CalendarSelectCommand: Command {
    let item: CalendarItem
    init(_ item: CalendarItem) {
        self.item = item
    }
    func execute(in store: Store) {
        item.isSelected = !item.isSelected
        let array: [[CalendarItem]] = store.state.calendar.calendars.map {
            $0.map {
                if $0.id == item.id {
                   return CalendarItem(event: $0.event, date: $0.date, title: $0.title, content: $0.content, isSelected: item.isSelected)
                } else {
                    return $0
                }
            }
        }
        store.dispatch(.calendarStore(array))
    }
}


struct CalendarDeleteCommand: Command {
    func execute(in store: Store) {
        let selecteArray:[CalendarItem] = store.state.calendar.calendars.flatMap {
            $0
        }.filter {
            $0.isSelected
        }
        
        let group = DispatchGroup()
        selecteArray.forEach {
            group.enter()
            do {
                try store.state.calendarStore.remove($0.event!, span: .futureEvents)
                group.leave()
            } catch let err {
                debugPrint("[caledar] 删除失败, error \(err)")
                group.leave()
            }
        }
        group.notify(queue: .main) {
            store.dispatch(.rootAlert(selecteArray.count > 1 ? "\(selecteArray.count) event cleaned up successfully" : "1 event cleaned up successfully"))
        }
        
        let result: [[CalendarItem]] = store.state.calendar.calendars.map {
            $0.filter {
                $0.isSelected == false
            }
        }.filter {
            $0.count > 0
        }
        store.dispatch(.calendarStore(result))
    }
}
