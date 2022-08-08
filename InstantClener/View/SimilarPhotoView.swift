//
//  SimilarPhotoView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/31.
//

import SwiftUI
import ASCollectionView_SwiftUI
import Photos

struct SimilarPhotoView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentModel
    var point: AppState.PhotoManagement.Point = .similarPhoto
    let colums: [GridItem] = [GridItem(.flexible(), spacing: 2.5), GridItem(.flexible(), spacing: 2.5), GridItem(.flexible(), spacing: 2.5), GridItem(.flexible(), spacing: 2.5)]
    
    var dataSource: [[PhotoItem]] {
        switch point {
        case .similarPhoto:
            return store.state.photoManagement.similarArray
        case .similarVideo:
            return store.state.photoManagement.similarVideoArray
        case .screenshot:
            return store.state.photoManagement.screenshotArray
        case .largePhoto:
            return store.state.photoManagement.largeArray
        case .blurryPhoto:
            return store.state.photoManagement.blurryArray
        case .largeVideo:
            return store.state.photoManagement.largeVideoArray
        }
    }
    
    var selectArray: [PhotoItem] {
        switch point {
        case .similarPhoto:
            return store.state.photoManagement.similarSelectArray
        case .similarVideo:
            return store.state.photoManagement.similarVideoSelectArray
        case .screenshot:
            return store.state.photoManagement.screenshotSelectArray
        case .largePhoto:
            return store.state.photoManagement.largeSelectArray
        case .blurryPhoto:
            return store.state.photoManagement.blurrySelectArray
        case .largeVideo:
            return store.state.photoManagement.largeVideoSelectArray
        }
    }
    
    var size: UInt64 {
        switch point {
        case .similarPhoto:
            return store.state.photoManagement.similarArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        case .similarVideo:
            return store.state.photoManagement.similarVideoArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        case .screenshot:
            return store.state.photoManagement.screenshotArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        case .largePhoto:
            return store.state.photoManagement.largeArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        case .blurryPhoto:
            return store.state.photoManagement.blurryArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        case .largeVideo:
            return store.state.photoManagement.largeVideoArray.flatMap {
                $0
            }.map {
                $0.imageDataLength
            }.reduce(0, +)
        }
    }
    
    var isEmpty: Bool {
        dataSource.flatMap {
            $0
        } .count == 0
    }
    
    var body: some View {
        ZStack{
            VStack {
                /// 图片视图
                ScrollView(showsIndicators: false){
                    LazyVGrid(columns: colums, alignment: .leading, spacing: 2.5){
                        ForEach(dataSource.indices, id: \.self) { section in
                            Section {
                                ForEach(dataSource[section]) { item in
                                    ItemView(item: item, isBest: point.isSmimilar ? item == dataSource[section].first : false, didSelected: {
                                        didSelect(item: item)
                                    })
                                        .frame(height: (UIScreen.main.bounds.size.width - 7.5) / CGFloat(colums.count))
                                }
                            } header: {
                                Text( point.headLine(num: dataSource[section].count, size: size))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: 0x232936))
                                    .padding(.leading, 16.0)
                                    .padding(.vertical, 12.0)
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
                    Text("No \(point.title)")
                }
            }
            
            if store.state.photoManagement.deleting {
                DeleteView()
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
        var item: PhotoItem
        var isBest: Bool = false
        var didSelected: ()->Void
        var body: some View {
            ZStack{
                Color.gray
                if let image = item.image {
                    Button {
                        didSelected()
                    } label: {
                        Image(uiImage: image)
                            .resizable(capInsets: EdgeInsets(), resizingMode: .tile)
                            .clipped()
                    }
                }
                
                VStack {
                    HStack{
                        if isBest {
                            Image("photo_best")
                        }
                        Spacer()
                        Image(item.isSelected ? "photo_select" : "photo_normal")
                    }
                    Spacer()
                    if item.second > 0 {
                        HStack{
                            Text(item.second.format())
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                    }
                }
                .padding([.top, .leading, .trailing], 6)
            }
        }
    }
}

extension SimilarPhotoView {
    func selectAllAction() {
        store.dispatch(.photoAllSelect(point, true))
    }
    
    func cancelAction() {
        store.dispatch(.photoCancel(point))
    }
    
    func deleteAction() {
        store.dispatch(.photoDelete(point))
        store.dispatch(.logEvent(.scanDelete))
    }
    
    func didSelect(item: PhotoItem) {
        store.dispatch(.photoDidselect(item))
    }
    
}

struct SimilarPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        SimilarPhotoView().environmentObject(Store())
    }
}

extension Int {
    func format() -> String {
        if self < 60 {
            return String(format: "00:%02d", self)
        } else if self < 60 * 60 {
            return String(format: "%02d:%02d", self / 60, self % 60)
        } else {
            let hour = self / 60 / 60
            let min = (self - self * 3600) / 60
            let sec = self % 60
            return String(format: "%d:%02d:%02d", hour, min, sec)
        }
    }
}
