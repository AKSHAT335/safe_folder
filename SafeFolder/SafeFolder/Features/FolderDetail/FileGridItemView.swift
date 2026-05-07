import SwiftUI

/// Grid square representing a single file
struct FileGridItemView: View {
    let file: FileItem
    let folder: Folder
    
    var body: some View {
        VStack {
            FileThumbnailView(file: file, folder: folder, size: 80)
            
            Text(file.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}
