// Standalone reproduction of the proposed helper's native-equivalence failures.
// Compile with swiftc -Onone or -O; exit status 1 means equivalence failed.
import CoreGraphics
import Foundation

private extension CGMutablePath {
	func addTransformedPath(_ path: CGPath, transform: CGAffineTransform) {
		var transform = transform
		guard let transformed = path.copy(using: &transform) else {
			addPath(path, transform: transform)
			return
		}
		addPath(transformed)
	}
}

private struct Element: Equatable {
	let type: CGPathElementType
	let points: [CGPoint]
}

private func elements(_ path: CGPath) -> [Element] {
	var result: [Element] = []
	path.applyWithBlock { pointer in
		let e = pointer.pointee
		let count: Int
		switch e.type {
		case .moveToPoint, .addLineToPoint: count = 1
		case .addQuadCurveToPoint: count = 2
		case .addCurveToPoint: count = 3
		case .closeSubpath: count = 0
		@unknown default: fatalError("Unexpected path element")
		}
		result.append(Element(type: e.type, points: Array(UnsafeBufferPointer(start: e.points, count: count))))
	}
	return result
}

private func raster(_ path: CGPath, mode: CGPathDrawingMode) -> [UInt8] {
	var bytes = [UInt8](repeating: 0, count: 96 * 96 * 4)
	bytes.withUnsafeMutableBytes { buffer in
		let context = CGContext(data: buffer.baseAddress, width: 96, height: 96,
			bitsPerComponent: 8, bytesPerRow: 96 * 4, space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
		context.translateBy(x: 32, y: 32)
		let color = CGColor(red: 0.15, green: 0.35, blue: 0.7, alpha: 0.65)
		context.setFillColor(color)
		context.setStrokeColor(color)
		context.setLineWidth(0.75)
		context.addPath(path)
		context.drawPath(using: mode)
	}
	return bytes
}

private func compare(_ label: String, destination: CGPath, source: CGPath) -> Bool {
	let transform = CGAffineTransform(translationX: 7.25, y: -3.5)
	let native = destination.mutableCopy()!
	let candidate = destination.mutableCopy()!
	native.addPath(source, transform: transform)
	candidate.addTransformedPath(source, transform: transform)
	let orderedElementsMatch = elements(native) == elements(candidate)
	let currentPointMatches = native.currentPoint == candidate.currentPoint
	let controlBoundsMatch = native.boundingBox == candidate.boundingBox
	let pathBoundsMatch = native.boundingBoxOfPath == candidate.boundingBoxOfPath
	print(label)
	print("  ordered elements equal:", orderedElementsMatch)
	print("  first move native/candidate:", elements(native).first!.points, elements(candidate).first!.points)
	print("  current point equal:", currentPointMatches)
	print("  control bounds native/candidate:", native.boundingBox, candidate.boundingBox)
	print("  path bounds native/candidate:", native.boundingBoxOfPath, candidate.boundingBoxOfPath)
	var rastersMatch = true
	for (name, mode): (String, CGPathDrawingMode) in [("nonzero fill", .fill), ("even-odd fill", .eoFill), ("stroke", .stroke)] {
		let differentBytes = zip(raster(native, mode: mode), raster(candidate, mode: mode)).filter { $0 != $1 }.count
		print("  \(name) different RGBA bytes:", differentBytes)
		rastersMatch = rastersMatch && differentBytes == 0
	}
	return orderedElementsMatch && currentPointMatches && controlBoundsMatch && pathBoundsMatch && rastersMatch
}

print(ProcessInfo.processInfo.operatingSystemVersionString)

// A populated destination whose only element is an unfinished move.
let moveOnly = CGMutablePath()
moveOnly.move(to: CGPoint(x: 3.25, y: 4.5))
let rect = CGPath(rect: CGRect(x: 1.25, y: 2.5, width: 17.75, height: 13.125), transform: nil)
let rectangleMatches = compare("Move-only destination + native rectangle", destination: moveOnly, source: rect)

// A destination with real geometry, and a source with multiple subpaths including
// quadratic/cubic controls outside the actual curve bounds.
let open = CGMutablePath()
open.move(to: CGPoint(x: 1.25, y: 2.5))
open.addLine(to: CGPoint(x: 18.75, y: 4))
open.addLine(to: CGPoint(x: 7, y: 19.5))
let closed = open.mutableCopy()!
closed.closeSubpath()
let quadratic = CGMutablePath()
quadratic.move(to: CGPoint(x: 1, y: 3))
quadratic.addQuadCurve(to: CGPoint(x: 21, y: 9), control: CGPoint(x: 6, y: 28))
let cubic = CGMutablePath()
cubic.move(to: CGPoint(x: 2, y: 1))
cubic.addCurve(to: CGPoint(x: 22, y: 19), control1: CGPoint(x: -8, y: 31), control2: CGPoint(x: 32, y: -7))
cubic.closeSubpath()
let mixed = CGMutablePath()
for path in [closed, quadratic, cubic, open] { mixed.addPath(path) }
let mixedMatches = compare("Closed destination + mixed multi-subpath source", destination: closed, source: mixed)

print("Native equivalence:", rectangleMatches && mixedMatches ? "PASS" : "FAIL")
exit(rectangleMatches && mixedMatches ? 0 : 1)
