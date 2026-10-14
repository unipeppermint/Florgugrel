// Rebuild with: swift scripts/GenerateIcon.swift
import AppKit
import CoreGraphics

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                        space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let ink = CGColor(red: 15/255, green: 14/255, blue: 14/255, alpha: 1)
let gold = CGColor(red: 232/255, green: 194/255, blue: 104/255, alpha: 1)
let paper = CGColor(red: 239/255, green: 231/255, blue: 216/255, alpha: 1)
context.setFillColor(ink)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setStrokeColor(gold.copy(alpha: 0.2)!)
context.setLineWidth(3)
for i in 0...5 {
    let value = CGFloat(192 + i * 128)
    context.move(to: CGPoint(x: 192, y: value)); context.addLine(to: CGPoint(x: 832, y: value))
    context.move(to: CGPoint(x: value, y: 192)); context.addLine(to: CGPoint(x: value, y: 832))
}
context.strokePath()
context.saveGState()
context.translateBy(x: 470, y: 530)
context.rotate(by: -0.18)
context.setFillColor(gold)
context.addPath(CGPath(roundedRect: CGRect(x: -198, y: -258, width: 396, height: 516), cornerWidth: 38, cornerHeight: 38, transform: nil))
context.fillPath()
context.restoreGState()
context.saveGState()
context.translateBy(x: 554, y: 510)
context.rotate(by: 0.1)
context.setShadow(offset: CGSize(width: 0, height: -15), blur: 40, color: ink)
context.setFillColor(paper)
context.addPath(CGPath(roundedRect: CGRect(x: -190, y: -250, width: 380, height: 500), cornerWidth: 34, cornerHeight: 34, transform: nil))
context.fillPath()
context.setShadow(offset: .zero, blur: 0, color: nil)
context.setStrokeColor(gold)
context.setLineWidth(4)
context.addPath(CGPath(roundedRect: CGRect(x: -168, y: -228, width: 336, height: 456), cornerWidth: 22, cornerHeight: 22, transform: nil))
context.strokePath()
// A geometric spade reads at small sizes and echoes the game's poker scoring.
context.setFillColor(ink)
context.move(to: CGPoint(x: 0, y: 142))
context.addCurve(to: CGPoint(x: -112, y: -14), control1: CGPoint(x: -24, y: 95), control2: CGPoint(x: -118, y: 44))
context.addCurve(to: CGPoint(x: -15, y: -52), control1: CGPoint(x: -113, y: -89), control2: CGPoint(x: -42, y: -94))
context.addLine(to: CGPoint(x: -42, y: -122))
context.addLine(to: CGPoint(x: 42, y: -122))
context.addLine(to: CGPoint(x: 15, y: -52))
context.addCurve(to: CGPoint(x: 112, y: -14), control1: CGPoint(x: 42, y: -94), control2: CGPoint(x: 113, y: -89))
context.addCurve(to: CGPoint(x: 0, y: 142), control1: CGPoint(x: 118, y: 44), control2: CGPoint(x: 24, y: 95))
context.fillPath()
context.restoreGState()
let image = NSBitmapImageRep(cgImage: context.makeImage()!)
try image.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Florgugrel/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
