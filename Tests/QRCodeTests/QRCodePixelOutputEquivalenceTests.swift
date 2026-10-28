import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import QRCode

/// Compare public output with frozen native accumulation, independently of addPixelPath.
final class QRCodePixelOutputEquivalenceTests: XCTestCase {
	private struct Pair {
		let name: String
		let actual: QRCodePixelShapeGenerator
		let native: QRCodePixelShapeGenerator
	}

	private func pairs() throws -> [Pair] {
		let standalone: [QRCodePixelShapeGenerator] = [
			QRCodeNativeStandalone.Grid2x2(), QRCodeNativeStandalone.Grid3x3(),
			QRCodeNativeStandalone.Grid4x4(), QRCodeNativeStandalone.Donut(),
			QRCodeNativeStandalone.DiagonalStripes(),
			QRCodeUnbatchedReference.Abstract(), QRCodeUnbatchedReference.RoundedPath(),
			QRCodeUnbatchedReference.Blob(), QRCodeUnbatchedReference.Circuit(),
			QRCodeUnbatchedReference.DripHorizontal(), QRCodeUnbatchedReference.DripVertical(),
			QRCodeUnbatchedReference.Crosshatch(), QRCodeUnbatchedReference.CurvePixel(),
			QRCodeUnbatchedReference.Pointy(), QRCodeUnbatchedReference.Razor(),
			QRCodeUnbatchedReference.RoundedEndIndent(), QRCodeUnbatchedReference.Vortex(),
			QRCodeUnbatchedReference.Horizontal(), QRCodeUnbatchedReference.Vertical(),
		]
		return try QRCodePixelShapeFactory.shared.all().map { actual in
			if let type = QRCode.PixelShape.NativeCommonPixelGenerator.PixelType(rawValue: actual.name) {
				let settings = actual.settings()
				let common = QRCode.PixelShape.NativeCommonPixelGenerator(pixelType: type,
					cornerRadiusFraction: CGFloatValue(settings[QRCode.SettingsKey.cornerRadiusFraction]) ?? 0,
					insetFraction: CGFloatValue(settings[QRCode.SettingsKey.insetFraction]) ?? 0,
					rotationFraction: CGFloatValue(settings[QRCode.SettingsKey.rotationFraction]) ?? 0)
				return Pair(name: actual.name, actual: actual,
					native: OutputTestGenerator(canGenerateEyes: actual.canGenerateEyeAndPupilShapes,
						generate: common.generatePath))
			}
			return Pair(name: actual.name, actual: actual,
				native: try XCTUnwrap(standalone.first { $0.name == actual.name }))
		}
	}

	func testEveryStyleThroughPublicImagesSVGAndPDF() throws {
		let code = try QRCode(utf8String: "Copy bounds", errorCorrection: .high, engine: QRCodeEngineCoreImage())
		let image = try patternImage()
		let logo = QRCode.LogoTemplate(image: image,
			path: CGPath(ellipseIn: CGRect(x: 0.35, y: 0.35, width: 0.3, height: 0.3), transform: nil))
		let cases = try pairs()
		XCTAssertEqual(cases.count, 43)
		var changedGeneratorBounds = Set<String>()
		var changedPublicBounds = Set<String>()
		for pair in cases {
			for variant in 0 ..< 4 {
				try autoreleasepool {
					let actual = try design(pair.actual, variant: variant, image: image)
					let native = try design(pair.native, variant: variant, image: image)
					let mask = variant == 1 || variant == 3 ? logo : nil
					let label = "\(pair.name), variant \(variant)"
					let size = CGSize(width: 197.25, height: 153.75)
					let a = pair.actual.generatePath(from: code.boolMatrix, size: size)
					let n = pair.native.generatePath(from: code.boolMatrix, size: size)
					if boundsDiffer(a.boundingBox, n.boundingBox) { changedGeneratorBounds.insert(pair.name) }
					for (component, name): (QRCode.Components, String) in [(.all, "all"), (.onPixels, "on"), (.offPixels, "off"), (.negative, "negative")] {
						for quiet: CGFloat in [0, 3.25] {
							let ap = code.path(size, components: component, shape: actual.shape, logoTemplate: mask, additionalQuietSpace: quiet)
							let np = code.path(size, components: component, shape: native.shape, logoTemplate: mask, additionalQuietSpace: quiet)
							if boundsDiffer(ap.boundingBox, np.boundingBox) { changedPublicBounds.insert("\(pair.name)/\(name)/quiet=\(quiet)") }
							XCTAssertFalse(boundsDiffer(ap.boundingBoxOfPath, np.boundingBoxOfPath), label + ": tight public bounds")
						}
					}
					for outputSize in [size, CGSize(width: 512, height: 512)] {
						let ai = try code.cgImage(outputSize, design: actual, logoTemplate: mask)
						let ni = try code.cgImage(outputSize, design: native, logoTemplate: mask)
						XCTAssertEqual(try pixels(ai), try pixels(ni), label + ": image")
					}
					let asvg = try code.svg(dimension: 197, design: actual, logoTemplate: mask)
					let nsvg = try code.svg(dimension: 197, design: native, logoTemplate: mask)
					XCTAssertTrue(asvg == nsvg, label + ": SVG bytes")
					let apdf = try code.pdfData(size, design: actual, logoTemplate: mask)
					let npdf = try code.pdfData(size, design: native, logoTemplate: mask)
					XCTAssertEqual(try pdfPixels(apdf), try pdfPixels(npdf), label + ": rendered PDF")
					let apng = try code.pngData(size, design: actual, logoTemplate: mask)
					let npng = try code.pngData(size, design: native, logoTemplate: mask)
					XCTAssertEqual(try decodedPixels(apng), try decodedPixels(npng), label + ": decoded PNG")
				}
			}
		}
		print("COPY-APPEND: \(cases.count) styles x 4 designs; bounds differences >1e-9: generator=\(changedGeneratorBounds.sorted()), public=\(changedPublicBounds.sorted())")
	}

	/// Force the known cache discrepancy rather than relying on built-in templates
	/// to expose it. Compare every fill style, both shadows and clipping.
	func testDifferentControlBoundsDoNotChangeLibraryDrawing() throws {
		let source = CGMutablePath()
		source.move(to: CGPoint(x: 1.25, y: 2.5))
		source.addLine(to: CGPoint(x: 18.75, y: 4))
		source.addLine(to: CGPoint(x: 7, y: 19.5))
		source.closeSubpath()
		source.move(to: CGPoint(x: 1, y: 3))
		source.addQuadCurve(to: CGPoint(x: 21, y: 9), control: CGPoint(x: 6, y: 28))
		source.move(to: CGPoint(x: 2, y: 1))
		source.addCurve(to: CGPoint(x: 22, y: 19), control1: CGPoint(x: -8, y: 31), control2: CGPoint(x: 32, y: -7))
		source.closeSubpath()
		let actual = CGMutablePath()
		actual.addRect(CGRect(x: 1.25, y: 2.5, width: 17.5, height: 17))
		let native = try XCTUnwrap(actual.mutableCopy())
		let transform = CGAffineTransform(translationX: 7.25, y: -3.5)
		actual.addPixelPath(source, transform: transform)
		native.addPath(source, transform: transform)
		// The cache discrepancy is OS-specific. Exercise output equality either way,
		// without requiring another CoreGraphics version to reproduce the same cache.
		print("COPY-APPEND synthetic control bounds differ: \(actual.boundingBox != native.boundingBox)")
		XCTAssertEqual(actual.boundingBoxOfPath, native.boundingBoxOfPath)
		XCTAssertEqual(actual.svgDataPath(), native.svgDataPath())
		let image = try patternImage()
		for variant in 0 ..< 4 {
			let fill = try design(OutputTestGenerator(generate: { _, _ in actual }), variant: variant, image: image).style.onPixels
			for shadow: QRCode.Shadow? in [nil, QRCode.Shadow(), QRCode.Shadow(.innerShadow, dx: 0.2, dy: -0.2, blur: 3, color: CGColor(gray: 0, alpha: 0.5))] {
				let a = try bitmap { fill.fill(ctx: $0, rect: CGRect(x: 0, y: 0, width: 64, height: 64), path: actual, expectedPixelSize: 5, shadow: shadow) }
				let n = try bitmap { fill.fill(ctx: $0, rect: CGRect(x: 0, y: 0, width: 64, height: 64), path: native, expectedPixelSize: 5, shadow: shadow) }
				XCTAssertEqual(a, n, "different bounds: fill \(variant), shadow \(String(describing: shadow?.type))")
			}
		}
	}

	private func design(_ generator: QRCodePixelShapeGenerator, variant: Int, image: CGImage) throws -> QRCode.Design {
		let design = QRCode.Design()
		design.shape.onPixels = generator
		let gradient = try DSFGradient(pins: [
			DSFGradient.Pin(CGColor(srgbRed: 0.15, green: 0.1, blue: 0.7, alpha: 0.8), 0),
			DSFGradient.Pin(CGColor(srgbRed: 0.7, green: 0.3, blue: 0.1, alpha: 1), 1)])
		switch variant {
		case 0:
			design.style.onPixels = QRCode.FillStyle.Solid(CGColor(gray: 0.1, alpha: 0.7))
		case 1:
			design.style.onPixels = QRCode.FillStyle.LinearGradient(gradient)
			design.style.shadow = QRCode.Shadow()
			design.additionalQuietZonePixels = 3
			design.shape.offPixels = generator
			design.shape.extendOffPixelsIntoEmptyQRCodeComponents = true
			design.style.offPixels = QRCode.FillStyle.Solid(CGColor(gray: 0.8, alpha: 0.5))
			design.style.onPixelsBackground = CGColor(gray: 1, alpha: 0.8)
			design.style.offPixelsBackground = CGColor(gray: 0.9, alpha: 0.8)
		case 2:
			design.style.onPixels = QRCode.FillStyle.RadialGradient(gradient)
			design.style.shadow = QRCode.Shadow(.innerShadow, dx: 0.2, dy: -0.2, blur: 3, color: CGColor(gray: 0, alpha: 0.5))
			design.shape.negatedOnPixelsOnly = true
			design.style.onPixelsBackground = CGColor(gray: 1, alpha: 0.8)
		case 3:
			design.style.onPixels = QRCode.FillStyle.Image(image)
			design.additionalQuietZonePixels = 4
			design.shape.eye = QRCode.EyeShape.UsePixelShape()
			design.shape.pupil = QRCode.PupilShape.UsePixelShape()
		default: fatalError("Unknown design")
		}
		return design
	}

	private func boundsDiffer(_ a: CGRect, _ b: CGRect) -> Bool {
		zip([a.minX, a.minY, a.maxX, a.maxY], [b.minX, b.minY, b.maxX, b.maxY]).contains { abs($0 - $1) > 1e-9 }
	}

	private func patternImage() throws -> CGImage {
		let context = try XCTUnwrap(CGContext(data: nil, width: 32, height: 32, bitsPerComponent: 8, bytesPerRow: 128,
			space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
		context.setFillColor(CGColor(srgbRed: 0.7, green: 0.2, blue: 0.1, alpha: 1))
		context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
		context.setFillColor(CGColor(srgbRed: 0.1, green: 0.2, blue: 0.7, alpha: 1))
		context.fill(CGRect(x: 0, y: 0, width: 16, height: 32))
		return try XCTUnwrap(context.makeImage())
	}

	private func pixels(_ image: CGImage) throws -> Data {
		try bitmap(width: image.width, height: image.height) { ctx in
			ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
		}
	}

	private func decodedPixels(_ data: Data) throws -> Data {
		let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
		return try pixels(XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil)))
	}

	private func pdfPixels(_ data: Data) throws -> Data {
		let provider = try XCTUnwrap(CGDataProvider(data: data as CFData))
		let document = try XCTUnwrap(CGPDFDocument(provider))
		let page = try XCTUnwrap(document.page(at: 1))
		let rect = page.getBoxRect(.mediaBox)
		return try bitmap(width: Int(ceil(rect.width * 2)), height: Int(ceil(rect.height * 2))) { context in
			context.scaleBy(x: 2, y: 2)
			context.drawPDFPage(page)
		}
	}

	private func bitmap(width: Int = 128, height: Int = 128, draw: (CGContext) -> Void) throws -> Data {
		let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
			bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
		draw(context)
		return Data(bytes: try XCTUnwrap(context.data), count: width * height * 4)
	}
}

private final class OutputTestGenerator: NSObject, QRCodePixelShapeGenerator {
	static let Name = "native-output-reference"
	static let Title = "Native output reference"
	let canGenerateEyeAndPupilShapes: Bool
	private let generate: (BoolMatrix, CGSize) -> CGPath
	init(canGenerateEyes: Bool = true, generate: @escaping (BoolMatrix, CGSize) -> CGPath) {
		self.canGenerateEyeAndPupilShapes = canGenerateEyes
		self.generate = generate
	}
	static func Create(_ settings: [String: Any]?) -> QRCodePixelShapeGenerator { fatalError("Test-only adapter") }
	func copyShape() -> QRCodePixelShapeGenerator { OutputTestGenerator(canGenerateEyes: canGenerateEyeAndPupilShapes, generate: generate) }
	func reset() {}
	func generatePath(from matrix: BoolMatrix, size: CGSize) -> CGPath { generate(matrix, size) }
	func settings() -> [String: Any] { [:] }
	func setSettingValue(_ value: Any?, forKey key: String) -> Bool { false }
	func supportsSettingValue(forKey key: String) -> Bool { false }
}
