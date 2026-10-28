import CoreGraphics
@testable import QRCode

protocol QRCodeUnbatchedGenerator: QRCodePixelShapeGenerator {
	var emittedPathCount: Int { get }
}

/// Test-only namespace: frozen geometry/traversal, with no dependency on batching.
enum QRCodeUnbatchedReference {
	final class Path {
		let result = CGMutablePath()
		private(set) var count = 0
		func addPath(_ path: CGPath, transform: CGAffineTransform = .identity) {
			result.addPath(path, transform: transform)
			count += 1
		}
		func closeSubpath() { result.closeSubpath() }
	}
}
