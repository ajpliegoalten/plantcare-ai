#if DEBUG && targetEnvironment(simulator)
import UIKit

enum IdentificationPhotoTestFixture {
    static func selections() -> [String: Data] {
        func image(_ color: UIColor, size: CGSize) -> Data {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).pngData { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
        return ["A": image(.systemGreen, size: CGSize(width: 120, height: 80)),
                "B": image(.systemOrange, size: CGSize(width: 80, height: 120)),
                "failure": Data("not an image".utf8)]
    }
}
#endif
