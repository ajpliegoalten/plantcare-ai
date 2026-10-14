import XCTest
import UIKit

@MainActor
final class LaunchBrandingResourcesTests: XCTestCase {
    func testBundleContainsLaunchStoryboardAndLocalBranding() throws {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "UIUserInterfaceStyle") as? String, "Light")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String], ["UIInterfaceOrientationPortrait"])
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String, "LaunchScreen")
        XCTAssertNotNil(Bundle.main.url(forResource: "LaunchScreen", withExtension: "storyboardc"))
        let icons = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any])
        let primary = try XCTUnwrap(icons["CFBundlePrimaryIcon"] as? [String: Any])
        XCTAssertEqual(primary["CFBundleIconName"] as? String, "AppIcon")
        XCTAssertEqual(try XCTUnwrap(UIImage(named: "LaunchBrand")).size, CGSize(width: 240, height: 240))
        XCTAssertEqual(try XCTUnwrap(UIImage(named: "LaunchAICapsule")).size, CGSize(width: 34, height: 22))
        XCTAssertNotNil(UIImage(named: "LaunchAtmosphere"))
    }

    func testNativeLaunchLayoutShowsCompleteBrandAndSubtitle() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.layoutIfNeeded()
        func descendants(_ view: UIView) -> [UIView] {
            [view] + view.subviews.flatMap(descendants)
        }
        let labels = descendants(controller.view).compactMap { $0 as? UILabel }
        XCTAssertEqual(Set(labels.compactMap(\.text)), Set([
            "PlantCare", "AI", "Inteligencia botánica en tu bolsillo para un cuidado consciente."
        ]))
        for label in labels {
            XCTAssertGreaterThan(label.bounds.width, 0)
            XCTAssertGreaterThan(label.bounds.height, 0)
            XCTAssertFalse(label.hasAmbiguousLayout)
            XCTAssertTrue(controller.view.bounds.contains(label.convert(label.bounds, to: controller.view)))
        }
        XCTAssertEqual(controller.view.backgroundColor, UIColor(named: "Background"))
        let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        let preview = XCTAttachment(image: image)
        preview.name = "launch-storyboard-preview-not-system-capture"
        preview.lifetime = .keepAlways
        add(preview)
    }
}
