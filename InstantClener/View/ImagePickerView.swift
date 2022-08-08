//
//  ImagePickerView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import BSImagePicker
import Photos
import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode

    let onImagePicked: ([UIImage])->Void
    
    
    final class Coordinator: NSObject, ImagePickerControllerDelegate {
        func imagePicker(_ imagePicker: ImagePickerController, didSelectAsset asset: PHAsset) {
            
        }
        
        func imagePicker(_ imagePicker: ImagePickerController, didDeselectAsset asset: PHAsset) {
            
        }
        
        func imagePicker(_ imagePicker: ImagePickerController, didFinishWithAssets assets: [PHAsset]) {
            let images: [UIImage] = assets.compactMap {
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.resizeMode = .fast
                var image: UIImage? = nil
                PHImageManager.default().requestImage(for: $0, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { resultImage, info in
                    image = resultImage
                }
                return image
            }
            onImagePicked(images)
        }
        
        func imagePicker(_ imagePicker: ImagePickerController, didCancelWithAssets assets: [PHAsset]) {
        }
        
        func imagePicker(_ imagePicker: ImagePickerController, didReachSelectionLimit count: Int) {
        }
        
        
        
        @Binding
        private var presentationMode: PresentationMode
        private let onImagePicked: ([UIImage]) -> Void
 
        init(presentationMode: Binding<PresentationMode>,
             onImagePicked: @escaping ([UIImage]) -> Void) {
            _presentationMode = presentationMode
            self.onImagePicked = onImagePicked
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, onImagePicked: onImagePicked)
    }
     
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        let viewController = ImagePickerController()
        viewController.settings.selection.max = 9
        viewController.imagePickerDelegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ImagePickerView>) {
    }

}
