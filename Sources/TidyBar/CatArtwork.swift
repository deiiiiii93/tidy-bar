import AppKit

/// Original vector artwork, shared by the app badge and menu bar control.
@MainActor
enum CatArtwork {
    static func draw(in rect: NSRect, color: NSColor, sleeping: Bool = true) {
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: rect.minX, yBy: rect.minY)
        transform.scaleX(by: rect.width / 100, yBy: rect.height / 100)
        transform.concat()
        color.setFill()
        let head = NSBezierPath()
        head.move(to: NSPoint(x: 19, y: 48))
        head.line(to: NSPoint(x: 17, y: 83))
        head.curve(to: NSPoint(x: 39, y: 70), controlPoint1: NSPoint(x: 17, y: 91), controlPoint2: NSPoint(x: 34, y: 77))
        head.curve(to: NSPoint(x: 61, y: 70), controlPoint1: NSPoint(x: 46, y: 73), controlPoint2: NSPoint(x: 54, y: 73))
        head.curve(to: NSPoint(x: 83, y: 83), controlPoint1: NSPoint(x: 66, y: 77), controlPoint2: NSPoint(x: 83, y: 91))
        head.line(to: NSPoint(x: 81, y: 48))
        head.curve(to: NSPoint(x: 19, y: 48), controlPoint1: NSPoint(x: 85, y: 9), controlPoint2: NSPoint(x: 15, y: 9))
        head.close()
        head.fill()
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        NSColor.black.setStroke()
        let eyes = NSBezierPath()
        eyes.lineWidth = 4.5
        eyes.lineCapStyle = .round
        for x: CGFloat in [35, 65] {
            if sleeping {
                eyes.move(to: NSPoint(x: x - 6, y: 51))
                eyes.curve(to: NSPoint(x: x + 6, y: 51), controlPoint1: NSPoint(x: x - 3, y: 46), controlPoint2: NSPoint(x: x + 3, y: 46))
            } else {
                eyes.move(to: NSPoint(x: x, y: 48))
                eyes.line(to: NSPoint(x: x, y: 56))
            }
        }
        eyes.stroke()
        let nose = NSBezierPath(ovalIn: NSRect(x: 47.5, y: 39, width: 5, height: 4))
        NSColor.black.setFill()
        nose.fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSGraphicsContext.restoreGraphicsState()
    }

    static func menuImage(hidden: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 22), flipped: false) { rect in
            draw(in: rect.insetBy(dx: 0, dy: 0), color: .black, sleeping: hidden)
            return true
        }
        image.isTemplate = true
        return image
    }

    static func appIcon(size: CGFloat = 1024) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 1024
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.scale(by: scale)
            transform.concat()
            let tile = NSBezierPath(roundedRect: NSRect(x: 58, y: 58, width: 908, height: 908), xRadius: 212, yRadius: 212)
            NSColor(calibratedRed: 0.75, green: 0.88, blue: 0.81, alpha: 1).setFill()
            tile.fill()
            let inset = NSBezierPath(roundedRect: NSRect(x: 82, y: 82, width: 860, height: 860), xRadius: 190, yRadius: 190)
            NSColor(calibratedWhite: 1, alpha: 0.35).setStroke()
            inset.lineWidth = 3
            inset.stroke()
            let halo = NSBezierPath(ovalIn: NSRect(x: 184, y: 205, width: 656, height: 656))
            NSColor(calibratedRed: 0.90, green: 0.96, blue: 0.88, alpha: 1).setFill()
            halo.fill()
            // Draw on a separate image so the eye cutouts do not erase the background.
            let cat = NSImage(size: NSSize(width: 600, height: 600), flipped: false) { area in
                draw(in: area, color: NSColor(calibratedRed: 0.17, green: 0.29, blue: 0.25, alpha: 1))
                return true
            }
            cat.draw(in: NSRect(x: 212, y: 250, width: 600, height: 600))
            let tray = NSBezierPath(roundedRect: NSRect(x: 227, y: 237, width: 570, height: 116), xRadius: 56, yRadius: 56)
            NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.86, alpha: 1).setFill()
            tray.fill()
            let handle = NSBezierPath(roundedRect: NSRect(x: 457, y: 278, width: 110, height: 20), xRadius: 10, yRadius: 10)
            NSColor(calibratedRed: 0.72, green: 0.78, blue: 0.65, alpha: 1).setFill()
            handle.fill()
            // A tiny four-point sparkle.
            let star = NSBezierPath()
            star.move(to: NSPoint(x: 795, y: 797))
            star.line(to: NSPoint(x: 807, y: 761))
            star.line(to: NSPoint(x: 843, y: 749))
            star.line(to: NSPoint(x: 807, y: 737))
            star.line(to: NSPoint(x: 795, y: 701))
            star.line(to: NSPoint(x: 783, y: 737))
            star.line(to: NSPoint(x: 747, y: 749))
            star.line(to: NSPoint(x: 783, y: 761))
            star.close()
            NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.89, alpha: 1).setFill()
            star.fill()
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
    }
}
