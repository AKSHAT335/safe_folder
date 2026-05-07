//
//  FilePreviewView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI
import QuickLook

/// A wrapper around QLPreviewController to display file previews (images, PDFs, videos, documents)
struct FilePreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        
        // Wrap in navigation controller for proper toolbar display
        let nav = UINavigationController(rootViewController: controller)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: FilePreviewView
        
        init(_ parent: FilePreviewView) {
            self.parent = parent
        }
        
        // MARK: - QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.fileURL as QLPreviewItem
        }
    }
}
