
import SwiftUI
@preconcurrency import QuickLook

/// A wrapper around QLPreviewController to display file previews (images, PDFs, videos, documents)
struct FilePreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        AppLogger.general.info("QLPreview: Attempting to preview \(fileURL.lastPathComponent)")
        
        // Final sanity check before passing to QuickLook
        if FileManager.default.fileExists(atPath: fileURL.path) {
            AppLogger.general.info("QLPreview: File exists at path: \(fileURL.path)")
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                let size = attrs[.size] as? Int64 ?? 0
                AppLogger.general.info("QLPreview: File size: \(size) bytes")
            }
        } else {
            AppLogger.general.error("QLPreview: File DOES NOT EXIST at path: \(fileURL.path)")
        }
        
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

final class Coordinator: NSObject, QLPreviewControllerDataSource {
    let parent: FilePreviewView
    
    init(parent: FilePreviewView) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return parent.fileURL as NSURL
    }
}
