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
            
            // Thread-safe collector to avoid captured var mutation warnings
            final class ImageCollector: @unchecked Sendable {
                private let queue = DispatchQueue(label: "com.safefolder.photopicker.collect")
                private var images: [UIImage] = []
                
                func append(_ image: UIImage) {
                    queue.sync { images.append(image) }
                }
                
                func getAll() -> [UIImage] {
                    queue.sync { images }
                }
            }
            
            let collector = ImageCollector()
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            collector.append(image)
                        }
                        group.leave()
                    }
                }
            }
            
            // Wait for all images to finish loading, then deliver on main thread
            group.notify(queue: .main) {
                let collected = collector.getAll()
                if !collected.isEmpty {
                    self.parent.onImagesPicked(collected)
                }
            }
        }
    }
}
