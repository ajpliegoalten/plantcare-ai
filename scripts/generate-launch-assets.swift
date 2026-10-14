// Run on macOS: swift scripts/generate-launch-assets.swift /path/to/approved-source.jpg
// Offline, development-only artwork generation; not part of the app or build phases.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("PlantCareAI/Assets.xcassets")
guard CommandLine.arguments.count == 2,
      let source = NSImage(contentsOfFile: CommandLine.arguments[1]) else {
    fatalError("Provide the approved square icon image as the sole argument.")
}

func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func bloom(in rect: NSRect, hex: Int, alpha: CGFloat) {
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [color(hex, alpha: alpha).cgColor, color(hex, alpha: 0).cgColor] as CFArray,
                              locations: [0, 1])!
    NSGraphicsContext.current!.cgContext.drawRadialGradient(
        gradient, startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0,
        endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: rect.width / 2, options: [])
}

func render(_ name: String, size: NSSize, scale: CGFloat = 1, opaque: Bool = false,
            draw: () -> Void) throws {
    let context = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale),
                            bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)!
    context.scaleBy(x: scale, y: scale)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.current!.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    let folder = name == "AppIcon" ? "AppIcon.appiconset" : "\(name).imageset"
    try bitmap.representation(using: .png, properties: [:])!
        .write(to: assets.appendingPathComponent("\(folder)/\(name).png"))
}

try render("AppIcon", size: NSSize(width: 1024, height: 1024), opaque: true) {
    source.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
}

try render("LaunchBrand", size: NSSize(width: 240, height: 240), scale: 3) {
    bloom(in: NSRect(x: 0, y: 0, width: 240, height: 240), hex: 0xC1ECD5, alpha: 0.6)
    let rect = NSRect(x: 48, y: 48, width: 144, height: 144)
    let shape = NSBezierPath(roundedRect: rect, xRadius: 32, yRadius: 32)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x002115, alpha: 0.22)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    color(0x264D3C).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    source.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

try render("LaunchAICapsule", size: NSSize(width: 34, height: 22), scale: 3) {
    color(0xC1ECD5).setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 34, height: 22), xRadius: 11, yRadius: 11).fill()
}

try render("LaunchAtmosphere", size: NSSize(width: 512, height: 1024)) {
    for (rect, hex, alpha) in [
        (NSRect(x: 50, y: 730, width: 410, height: 410), 0xC1ECD5, 0.18),
        (NSRect(x: 340, y: 390, width: 330, height: 330), 0xFFDBCF, 0.10),
        (NSRect(x: -150, y: -120, width: 420, height: 420), 0xA6D0BA, 0.10)
    ] {
        bloom(in: rect, hex: hex, alpha: alpha)
    }
}
