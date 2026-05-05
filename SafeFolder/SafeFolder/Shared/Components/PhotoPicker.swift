//
//  PhotoPicker.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI
import PhotosUI

/// A wrapper around PHPickerViewController to select multiple images from the Photo Library
struct PhotoPicker: UIViewControllerRepresentable {
    var onImagesPicked: ([UIImage]) -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0 // 0 means unlimited multiple selection
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            guard !results.isEmpty else { return }
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            // Safely append to array on main thread
                            DispatchQueue.main.async {
                                images.append(image)
                            }
                        }
                        group.leave()
                    }
                }
            }
            
            // Wait for all images to finish loading from providers
            group.notify(queue: .main) {
                if !images.isEmpty {
                    self.parent.onImagesPicked(images)
                }
            }
        }
    }
}
