//
//  ContactView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import Foundation
import SwiftUI

struct ContactView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentModel
    
    let colums: [GridItem] = [GridItem(.flexible())]

    var point: AppState.Contact.Point = .duplicateNumber
    
    var selectArray: [ContactItem] {
        switch point {
        case .duplicateNumber:
            return store.state.contact.duplicationNumber.flatMap {
                $0
            }.filter {
                $0.isSelected == true
            }
        case .duplicateName:
            return store.state.contact.duplicationName.flatMap {
                $0
            }.filter {
                $0.isSelected == true
            }
        case .noNumber:
            return store.state.contact.noNumber.flatMap {
                $0
            }.filter {
                $0.isSelected == true
            }
        case .noName:
            return store.state.contact.noName.flatMap {
                $0
            }.filter {
                $0.isSelected == true
            }
        }
    }
    
    var dataSource: [[ContactItem]] {
        switch point {
        case .duplicateName:
            return store.state.contact.duplicationName
        case .duplicateNumber:
            return store.state.contact.duplicationNumber
        case .noName:
            return store.state.contact.noName
        case .noNumber:
            return store.state.contact.noNumber
        }
    }
    
    var isEmpty: Bool {
        dataSource.count == 0
    }
    
    var body: some View {
        ZStack {
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
                                switch point {
                                case .duplicateName:
                                    Text("Duplicate Contact: \(dataSource[section][0].name)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: 0x232936))
                                case .duplicateNumber:
                                    Text("Duplicate Number: \(dataSource[section][0].number)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: 0x232936))
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .padding(.all, 16)
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
                    switch point {
                    case .duplicateNumber:
                        Text("No contact with duplicate number")
                            .foregroundColor(Color(hex: 0x74797F))
                    case .duplicateName:
                        Text("No contact with duplicate name")
                            .foregroundColor(Color(hex: 0x74797F))
                    case .noName:
                        Text("No contact without name")
                            .foregroundColor(Color(hex: 0x74797F))
                    case .noNumber:
                        Text("No contact without number")
                            .foregroundColor(Color(hex: 0x74797F))
                    }
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
                    self.presentModel.wrappedValue.dismiss()
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle(point.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    struct ItemView: View {
        var item: ContactItem
        var body: some View {
            VStack{
                HStack(spacing: 12){
                    Image("contact_placeholder")
                    VStack(alignment: .leading, spacing: 5){
                        Text(item.n)
                            .font(.system(size: 15.0))
                            .foregroundColor(Color(hex: 0x232936))
                        Text(item.p)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x74797F))
                    }
                    Spacer()
                    Image(item.isSelected ? "photo_select" : "contact_normal")
                }
                Divider()
                    .padding(.leading, 40)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }
}

extension ContactView {
    func cancelAction() {
        store.dispatch(.contactCancel)
    }
    
    func selectAllAction() {
        store.dispatch(.contactAllSelect(point))
    }
    
    func deleteAction() {
        store.dispatch(.contactDelete)
        store.dispatch(.logEvent(.scanDelete))
    }
    
    func didSelect(item: ContactItem) {
        store.dispatch(.contactSelect(item))
    }
}
