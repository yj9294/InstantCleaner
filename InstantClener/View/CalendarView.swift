//
//  CalendarView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentModel
    @State var isAlerDelete: Bool = false
    var selectArray: [CalendarItem] {
        store.state.calendar.calendars.flatMap {
            $0
        }.filter {
            $0.isSelected == true
        }
    }
    
    let colums: [GridItem] = [GridItem(.flexible())]

    var dataSource: [[CalendarItem]] {
        store.state.calendar.calendars
    }
    
    var isEmpty: Bool {
        dataSource.count == 0
    }
    
    var body: some View {
        ZStack{
            VStack{
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: colums, alignment: .leading, spacing: 2.5){
                        ForEach(dataSource.indices, id: \.self) { section in
                            Section {
                                ForEach(dataSource[section]) { item in
                                    Button {
                                        didSelect(item: item)
                                    } label: {
                                        ItemView(item: item)
                                    }
                                }
                            } header: {
                                HStack{
                                    Text(dataSource[section][0].date)
                                        .foregroundColor(Color.white)
                                        .font(.system(size: 21, weight: .bold))
                                        .padding([.top,.leading,.bottom], 16)
                                    Spacer()
                                }.background(Color(hex: 0x283C4D))
                            }
                        }
                    }
                }
                .padding(.top, 5)
                
                
                /// 按钮
                if !isEmpty {
                    VStack{
                        if selectArray.count > 0 {
                            Button(action: deleteAction) {
                                Text("Delete Selected (\(selectArray.count))")
                                    .foregroundColor(.white)
                                    .frame(width: 285, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24.0)
                                            .fill(LinearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    )
                            }
                        } else {
                            Text("Delete Selected (0)")
                                .foregroundColor(Color(hex: 0xffffff, alpha: 0.3))
                                .frame(width: 285, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 24.0)
                                        .fill(LinearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                        }
                    }
                    .padding(.vertical, 14.0)
                }
            }
            
            if isEmpty {
                VStack(spacing: 20){
                    Image("placeholder")
                    Text("No schedule")
                        .foregroundColor(Color(hex: 0x74797F))
                }
            }
            
            if store.state.root.isAlert {
                AlertView(message: store.state.root.alertMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.state.root.isAlert = false
                        }
                    }
            }
        }
        .alert(isPresented: $isAlerDelete) {
            Alert(title: Text("Delete selected schedule.(\(selectArray.count))"), message: Text("The event will be removed from the calendar."), primaryButton: .default(Text("Cancel")), secondaryButton: .default(Text("Delete"), action: {
                store.dispatch(.calendarDelete)
                store.dispatch(.logEvent(.scanDelete))
            }))
        }
        .background(Color(hex: 0xE2F3FF).ignoresSafeArea())
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if selectArray.count > 0 {
                        cancelAction()
                    } else {
                        selectAllAction()
                    }
                } label: {
                    if !isEmpty {
                        Text(!(selectArray.count > 0) ? "Select All" : "Cancel")
                        .foregroundColor(Color(hex: 0x2961FF))
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    store.dispatch(.loadingPresent(false))
                    store.dispatch(.homeStartScanAnimation)
                    store.dispatch(.logEvent(.homeShow))
                    store.dispatch(.logEvent(.homeScan))
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle("Calendar Management")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    struct ItemView: View {
        var item: CalendarItem
        var body: some View{
            HStack{
                VStack(alignment: .leading, spacing: 7){
                    Text(item.titleString)
                        .foregroundColor(Color(hex: 0x232936))
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                    Text(item.content)
                        .foregroundColor(Color(hex: 0x74797F))
                        .font(.system(size: 12))
                }
                Spacer()
                Image(item.isSelected ? "photo_select" : "contact_normal")
            }
            .padding(.all, 16)
        }
    }
}

extension CalendarView {
    func cancelAction() {
        store.dispatch(.calendarCancel)
    }
    
    func selectAllAction() {
        store.dispatch(.calendarAllSelect)
    }
    
    func deleteAction() {
        isAlerDelete = true
    }
    
    func didSelect(item: CalendarItem) {
        store.dispatch(.calendarSelect(item))
    }
}
