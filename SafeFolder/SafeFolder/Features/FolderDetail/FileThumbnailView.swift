import SwiftUI

/// Reusable thumbnail view for files, showing either the actual image preview or a generic icon
struct FileThumbnailView: View {
    let file: FileItem
    let folder: Folder
    let size: CGFloat
    
    var body: some View {
        Group {
            if file.fileType == .image {
                let url = StorageService.shared.fileURL(for: file, in: folder)
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    fallbackIcon
                }
            } else {
                fallbackIcon
            }
        }
    }
    
    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: size, height: size)
            
            Image(systemName: file.fileType.iconName)
                .font(.system(size: size * 0.4))
                .foregroundColor(.accentColor)
        }
    }
}
