import AppKit
import TidyBarCore

/// Original rounded line drawings, designed to stay legible at 22 points.
@MainActor
enum AnimalArtwork {
    static func menuImage(animal: MenuBarAnimal, hidden: Bool, size: CGFloat = 22) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            draw(animal: animal, in: rect, sleeping: hidden)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(animal: MenuBarAnimal, in rect: NSRect, sleeping: Bool) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = NSAffineTransform()
        transform.translateX(by: rect.minX, yBy: rect.minY)
        transform.scaleX(by: rect.width / 100, yBy: rect.height / 100)
        transform.concat()
        NSColor.black.setFill()
        NSColor.black.setStroke()

        func stroke(_ width: CGFloat = 5, _ build: (NSBezierPath) -> Void) {
            let p = NSBezierPath()
            p.lineWidth = width
            p.lineCapStyle = .round
            p.lineJoinStyle = .round
            build(p)
            p.stroke()
        }
        func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, filled: Bool = false) {
            let p = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h))
            p.lineWidth = 5
            if filled { p.fill() } else { p.stroke() }
        }
        func eyes(_ left: CGFloat, _ right: CGFloat, y: CGFloat) {
            for x in [left, right] {
                if sleeping {
                    stroke(4.5) { p in
                        p.move(to: .init(x: x - 5, y: y + 1))
                        p.curve(to: .init(x: x + 5, y: y + 1), controlPoint1: .init(x: x - 3, y: y - 4), controlPoint2: .init(x: x + 3, y: y - 4))
                    }
                } else {
                    oval(x - 3, y - 4, 6, 8, filled: true)
                }
            }
        }
        func nose(_ y: CGFloat) {
            let p = NSBezierPath()
            p.move(to: .init(x: 45, y: y + 3))
            p.curve(to: .init(x: 55, y: y + 3), controlPoint1: .init(x: 47, y: y + 5), controlPoint2: .init(x: 53, y: y + 5))
            p.curve(to: .init(x: 50, y: y - 3), controlPoint1: .init(x: 56, y: y + 1), controlPoint2: .init(x: 52, y: y - 2))
            p.curve(to: .init(x: 45, y: y + 3), controlPoint1: .init(x: 48, y: y - 2), controlPoint2: .init(x: 44, y: y + 1))
            p.fill()
        }
        func smile(_ y: CGFloat) {
            stroke(3.5) { p in
                p.move(to: .init(x: 50, y: y + 3))
                p.line(to: .init(x: 50, y: y - 2))
                p.curve(to: .init(x: 42, y: y - 4), controlPoint1: .init(x: 48, y: y - 7), controlPoint2: .init(x: 44, y: y - 7))
                p.move(to: .init(x: 50, y: y - 2))
                p.curve(to: .init(x: 58, y: y - 4), controlPoint1: .init(x: 52, y: y - 7), controlPoint2: .init(x: 56, y: y - 7))
            }
        }

        switch animal {
        case .cat:
            stroke { p in
                p.move(to: .init(x: 15, y: 52))
                p.line(to: .init(x: 14, y: 84))
                p.curve(to: .init(x: 36, y: 73), controlPoint1: .init(x: 14, y: 91), controlPoint2: .init(x: 31, y: 78))
                p.curve(to: .init(x: 64, y: 73), controlPoint1: .init(x: 44, y: 76), controlPoint2: .init(x: 56, y: 76))
                p.curve(to: .init(x: 86, y: 84), controlPoint1: .init(x: 69, y: 78), controlPoint2: .init(x: 86, y: 91))
                p.line(to: .init(x: 85, y: 52))
                p.curve(to: .init(x: 15, y: 52), controlPoint1: .init(x: 91, y: 6), controlPoint2: .init(x: 9, y: 6))
                p.close()
            }
            eyes(34, 66, y: 51); nose(40); smile(34)
            stroke(3.5) { p in
                for x: CGFloat in [18, 72] {
                    p.move(to: .init(x: x, y: 43)); p.line(to: .init(x: x + 10, y: 40))
                    p.move(to: .init(x: x, y: 33)); p.line(to: .init(x: x + 10, y: 34))
                }
            }
        case .bunny:
            stroke { p in
                p.move(to: .init(x: 25, y: 59))
                p.curve(to: .init(x: 23, y: 88), controlPoint1: .init(x: 20, y: 70), controlPoint2: .init(x: 18, y: 82))
                p.curve(to: .init(x: 43, y: 63), controlPoint1: .init(x: 35, y: 106), controlPoint2: .init(x: 44, y: 77))
                p.curve(to: .init(x: 57, y: 63), controlPoint1: .init(x: 47, y: 65), controlPoint2: .init(x: 53, y: 65))
                p.curve(to: .init(x: 77, y: 88), controlPoint1: .init(x: 56, y: 77), controlPoint2: .init(x: 65, y: 106))
                p.curve(to: .init(x: 75, y: 59), controlPoint1: .init(x: 82, y: 82), controlPoint2: .init(x: 80, y: 70))
                p.curve(to: .init(x: 50, y: 12), controlPoint1: .init(x: 97, y: 32), controlPoint2: .init(x: 75, y: 12))
                p.curve(to: .init(x: 25, y: 59), controlPoint1: .init(x: 25, y: 12), controlPoint2: .init(x: 3, y: 32))
                p.close()
            }
            stroke(3.5) { p in
                p.move(to: .init(x: 29, y: 84)); p.line(to: .init(x: 34, y: 69))
                p.move(to: .init(x: 71, y: 84)); p.line(to: .init(x: 66, y: 69))
            }
            eyes(35, 65, y: 44); nose(34); smile(28)
        case .bear, .mouse:
            let mouse = animal == .mouse
            let ear = mouse ? CGFloat(32) : CGFloat(24)
            let left = mouse ? CGFloat(9) : CGFloat(15)
            let top = mouse ? CGFloat(58) : CGFloat(62)
            // Mask the lower ear arcs behind the face so the contours stay clean.
            oval(left, top, ear, ear)
            oval(100 - left - ear, top, ear, ear)
            let head = NSBezierPath()
            head.move(to: .init(x: 26, y: 68))
            head.curve(to: .init(x: 74, y: 68), controlPoint1: .init(x: 38, y: 80), controlPoint2: .init(x: 62, y: 80))
            head.curve(to: .init(x: 50, y: 14), controlPoint1: .init(x: 99, y: 45), controlPoint2: .init(x: 84, y: 14))
            head.curve(to: .init(x: 26, y: 68), controlPoint1: .init(x: 16, y: 14), controlPoint2: .init(x: 1, y: 45))
            head.close()
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            head.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            head.lineWidth = 5
            head.lineJoinStyle = .round
            head.stroke()
            eyes(34, 66, y: 49)
            if mouse {
                nose(36)
                stroke(3.5) { p in
                    for x: CGFloat in [9, 72] {
                        p.move(to: .init(x: x, y: 38)); p.line(to: .init(x: x + 19, y: 34))
                        p.move(to: .init(x: x, y: 25)); p.line(to: .init(x: x + 19, y: 28))
                    }
                }
            } else {
                oval(36, 23, 28, 22); nose(36); smile(30)
            }
        case .fox:
            stroke { p in
                p.move(to: .init(x: 12, y: 82))
                p.curve(to: .init(x: 37, y: 73), controlPoint1: .init(x: 9, y: 94), controlPoint2: .init(x: 30, y: 80))
                p.curve(to: .init(x: 63, y: 73), controlPoint1: .init(x: 44, y: 77), controlPoint2: .init(x: 56, y: 77))
                p.curve(to: .init(x: 88, y: 82), controlPoint1: .init(x: 70, y: 80), controlPoint2: .init(x: 91, y: 94))
                p.line(to: .init(x: 83, y: 49)); p.line(to: .init(x: 90, y: 47))
                p.curve(to: .init(x: 50, y: 14), controlPoint1: .init(x: 78, y: 31), controlPoint2: .init(x: 65, y: 15))
                p.curve(to: .init(x: 10, y: 47), controlPoint1: .init(x: 35, y: 15), controlPoint2: .init(x: 22, y: 31))
                p.line(to: .init(x: 17, y: 49)); p.close()
            }
            eyes(34, 66, y: 54); nose(26)
            stroke(4) { p in
                p.move(to: .init(x: 21, y: 48))
                p.curve(to: .init(x: 45, y: 30), controlPoint1: .init(x: 37, y: 47), controlPoint2: .init(x: 40, y: 37))
                p.move(to: .init(x: 79, y: 48))
                p.curve(to: .init(x: 55, y: 30), controlPoint1: .init(x: 63, y: 47), controlPoint2: .init(x: 60, y: 37))
            }
        case .dog:
            stroke { p in
                p.move(to: .init(x: 29, y: 70))
                p.curve(to: .init(x: 71, y: 70), controlPoint1: .init(x: 40, y: 82), controlPoint2: .init(x: 60, y: 82))
                p.curve(to: .init(x: 83, y: 30), controlPoint1: .init(x: 100, y: 76), controlPoint2: .init(x: 99, y: 20))
                p.curve(to: .init(x: 72, y: 59), controlPoint1: .init(x: 74, y: 29), controlPoint2: .init(x: 76, y: 49))
                p.move(to: .init(x: 29, y: 70))
                p.curve(to: .init(x: 17, y: 30), controlPoint1: .init(x: 0, y: 76), controlPoint2: .init(x: 1, y: 20))
                p.curve(to: .init(x: 28, y: 59), controlPoint1: .init(x: 26, y: 29), controlPoint2: .init(x: 24, y: 49))
                p.move(to: .init(x: 25, y: 47))
                p.curve(to: .init(x: 75, y: 47), controlPoint1: .init(x: 15, y: 4), controlPoint2: .init(x: 85, y: 4))
            }
            eyes(36, 64, y: 51); nose(37); smile(31)
        case .pig:
            stroke { p in
                p.move(to: .init(x: 22, y: 66))
                p.curve(to: .init(x: 14, y: 82), controlPoint1: .init(x: 17, y: 73), controlPoint2: .init(x: 11, y: 79))
                p.curve(to: .init(x: 37, y: 72), controlPoint1: .init(x: 22, y: 88), controlPoint2: .init(x: 30, y: 78))
                p.curve(to: .init(x: 63, y: 72), controlPoint1: .init(x: 45, y: 76), controlPoint2: .init(x: 55, y: 76))
                p.curve(to: .init(x: 86, y: 82), controlPoint1: .init(x: 70, y: 78), controlPoint2: .init(x: 78, y: 88))
                p.curve(to: .init(x: 78, y: 66), controlPoint1: .init(x: 89, y: 79), controlPoint2: .init(x: 83, y: 73))
                p.curve(to: .init(x: 50, y: 14), controlPoint1: .init(x: 102, y: 39), controlPoint2: .init(x: 85, y: 14))
                p.curve(to: .init(x: 22, y: 66), controlPoint1: .init(x: 15, y: 14), controlPoint2: .init(x: -2, y: 39))
                p.close()
            }
            eyes(33, 67, y: 52)
            oval(30, 24, 40, 23)
            oval(40, 31, 5, 8, filled: true); oval(55, 31, 5, 8, filled: true)
        case .owl:
            stroke { p in
                p.move(to: .init(x: 16, y: 79))
                p.curve(to: .init(x: 35, y: 74), controlPoint1: .init(x: 12, y: 92), controlPoint2: .init(x: 30, y: 79))
                p.curve(to: .init(x: 65, y: 74), controlPoint1: .init(x: 44, y: 77), controlPoint2: .init(x: 56, y: 77))
                p.curve(to: .init(x: 84, y: 79), controlPoint1: .init(x: 70, y: 79), controlPoint2: .init(x: 88, y: 92))
                p.curve(to: .init(x: 50, y: 13), controlPoint1: .init(x: 96, y: 28), controlPoint2: .init(x: 77, y: 13))
                p.curve(to: .init(x: 16, y: 79), controlPoint1: .init(x: 23, y: 13), controlPoint2: .init(x: 4, y: 28))
                p.close()
            }
            oval(21, 36, 28, 30); oval(51, 36, 28, 30)
            eyes(35, 65, y: 51)
            let beak = NSBezierPath()
            beak.move(to: .init(x: 45, y: 36)); beak.line(to: .init(x: 55, y: 36))
            beak.line(to: .init(x: 50, y: 28)); beak.close(); beak.fill()
        }
    }
}
