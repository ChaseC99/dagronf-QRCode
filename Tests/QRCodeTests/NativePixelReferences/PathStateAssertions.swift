import CoreGraphics
import XCTest

func XCTAssertPathStateEqual(_ actual: CGPath, _ expected: CGPath, label: String,
	file: StaticString = #filePath, line: UInt = #line) {
	// A template may contain open contours, but no move-only subpath may be left
	// pending when the next transformed template is appended.
	var previous: CGPathElementType?
	actual.applyWithBlock { pointer in
		let type = pointer.pointee.type
		if type == .moveToPoint {
			XCTAssertNotEqual(previous, .moveToPoint, label + ": consecutive moves", file: file, line: line)
		}
		previous = type
	}
	XCTAssertNotEqual(previous, .moveToPoint, label + ": pending final move", file: file, line: line)
	XCTAssertEqual(actual.isEmpty, expected.isEmpty, label, file: file, line: line)
	XCTAssertEqual(actual.currentPoint.x, expected.currentPoint.x, accuracy: 1e-10, label + ": current x", file: file, line: line)
	XCTAssertEqual(actual.currentPoint.y, expected.currentPoint.y, accuracy: 1e-10, label + ": current y", file: file, line: line)
	// CoreGraphics' identity-append cache may report tight rather than control-point
	// bounds. The library does not consume pixel control bounds; compare geometric
	// bounds and exact rendered output instead (see QRCodePixelOutputEquivalenceTests).
	for (name, a, e) in [("path bounds", actual.boundingBoxOfPath, expected.boundingBoxOfPath)] {
		if a.isNull || e.isNull { XCTAssertEqual(a, e, label + ": " + name, file: file, line: line) }
		else {
			for (av, ev) in [(a.minX, e.minX), (a.minY, e.minY), (a.maxX, e.maxX), (a.maxY, e.maxY)] {
				XCTAssertEqual(av, ev, accuracy: 1e-10, label + ": " + name, file: file, line: line)
			}
		}
	}
}
