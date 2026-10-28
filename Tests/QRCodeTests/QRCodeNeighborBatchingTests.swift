import CoreGraphics
import Foundation
import XCTest
@testable import QRCode

final class QRCodeNeighborBatchingTests: XCTestCase {
	private struct Pair {
		let actual: QRCodePixelShapeGenerator
		let reference: QRCodeUnbatchedGenerator
	}

	private var pairs: [Pair] {
		[
			Pair(actual: QRCode.PixelShape.Abstract(), reference: QRCodeUnbatchedReference.Abstract()),
			Pair(actual: QRCode.PixelShape.RoundedPath(), reference: QRCodeUnbatchedReference.RoundedPath()),
			Pair(actual: QRCode.PixelShape.Blob(), reference: QRCodeUnbatchedReference.Blob()),
			Pair(actual: QRCode.PixelShape.Circuit(), reference: QRCodeUnbatchedReference.Circuit()),
			Pair(actual: QRCode.PixelShape.DripHorizontal(), reference: QRCodeUnbatchedReference.DripHorizontal()),
			Pair(actual: QRCode.PixelShape.DripVertical(), reference: QRCodeUnbatchedReference.DripVertical()),
			Pair(actual: QRCode.PixelShape.Crosshatch(), reference: QRCodeUnbatchedReference.Crosshatch()),
			Pair(actual: QRCode.PixelShape.CurvePixel(), reference: QRCodeUnbatchedReference.CurvePixel()),
			Pair(actual: QRCode.PixelShape.Pointy(), reference: QRCodeUnbatchedReference.Pointy()),
			Pair(actual: QRCode.PixelShape.Razor(), reference: QRCodeUnbatchedReference.Razor()),
			Pair(actual: QRCode.PixelShape.RoundedEndIndent(), reference: QRCodeUnbatchedReference.RoundedEndIndent()),
			Pair(actual: QRCode.PixelShape.Vortex(), reference: QRCodeUnbatchedReference.Vortex()),
			Pair(actual: QRCode.PixelShape.Horizontal(), reference: QRCodeUnbatchedReference.Horizontal()),
			Pair(actual: QRCode.PixelShape.Vertical(), reference: QRCodeUnbatchedReference.Vertical()),
			Pair(actual: QRCode.PixelShape.RoundedPath(hasInnerCorners: false),
				reference: QRCodeUnbatchedReference.RoundedPath(hasInnerCorners: false)),
			Pair(actual: QRCode.PixelShape.RoundedEndIndent(hasInnerCorners: true),
				reference: QRCodeUnbatchedReference.RoundedEndIndent(hasInnerCorners: true)),
		]
	}

	func testAll512NeighborhoodsIncludingEdgesAndVortexQuadrants() throws {
		// The full 3×3 input covers real edges/corners. Embedded copies cover interior
		// cells in every quadrant, and odd/even dimensions. Never mask out neighbors.
		let placements = [(3, 0, 0), (6, 1, 1), (7, 1, 1), (7, 1, 3), (7, 3, 1), (7, 3, 3)]
		for pair in pairs {
			for pattern in 0 ..< 512 {
				for (dimension, top, left) in placements {
					let input = BoolMatrix(dimension: dimension)
					for bit in 0 ..< 9 where pattern & (1 << bit) != 0 {
						input[top + bit / 3, left + bit % 3] = true
					}
					try check(pair, matrix: input, size: CGSize(width: 47.25, height: 39.75))
				}
			}
		}
	}

	func testEmptySingleSparseDenseAndActiveCountBoundaries() throws {
		for pair in pairs {
			for dimension in [0, 1, 8, 9, 12, 13] {
				try check(pair, matrix: BoolMatrix(dimension: dimension))
				if dimension > 0 {
					for count in Set([1, min(4, dimension * dimension), dimension * dimension]) {
						try check(pair, matrix: matrix(dimension: dimension, activeCount: count))
					}
				}
			}
			for dimension in [12, 13] {
				for count in [63, 64, 65, 127, 128, 129] {
					try check(pair, matrix: matrix(dimension: dimension, activeCount: count),
						size: CGSize(width: 153.75, height: 197.25))
				}
			}
		}
	}

	func testExactEmittedPathBoundaries() throws {
		for pair in pairs {
			for dimension in [25, 26] {
				for count in [63, 64, 65, 127, 128, 129] {
					let input = BoolMatrix(dimension: dimension)
					var remaining = count
					for row in stride(from: 0, to: dimension, by: 2) {
						for col in stride(from: 0, to: dimension, by: 2) where remaining > 0 {
							// Vortex emits an odd center once per ring: preserve and test that
							// in the dense cases, but exclude it from this exact-count fixture.
							if dimension % 2 == 1 && row == dimension / 2 && col == row { continue }
							input[row, col] = true
							remaining -= 1
						}
					}
					XCTAssertEqual(remaining, 0)
					try check(pair, matrix: input)
					XCTAssertEqual(pair.reference.emittedPathCount, count, pair.actual.name)
					// A new call must start with an empty accumulator.
					try check(pair, matrix: input)
				}
			}
		}
	}

	func testOffCellEmissionsAcrossExactBatchBoundaries() throws {
		let offCellPairs = pairs.filter {
			["roundedPath", "roundedEndIndent", "blob", "razor"].contains($0.actual.name)
				&& ($0.actual.settings()[QRCode.SettingsKey.hasInnerCorners] as? Bool ?? true)
		}
		XCTAssertEqual(offCellPairs.count, 4)
		for pair in offCellPairs {
			for count in [63, 64, 65, 127, 128, 129] {
				let input = BoolMatrix(dimension: 29)
				let rings = count < 100 ? 5 : 10
				for index in 0 ..< rings {
					let top = 2 + (index / 5) * 5
					let left = 2 + (index % 5) * 5
					for bit in 0 ..< 9 where bit != 4 {
						input[top + bit / 3, left + bit % 3] = true
					}
				}
				for index in 0 ..< count - rings * 12 { input[27, 1 + index * 3] = true }
				try check(pair, matrix: input)
				XCTAssertEqual(pair.reference.emittedPathCount, count, pair.actual.name)
				XCTAssertGreaterThan(pair.reference.emittedPathCount, input.flattened.filter { $0 }.count)
			}
		}
	}

	func testCustomAndDegenerateSettings() throws {
		for pair in pairs where pair.actual.supportsSettingValue(forKey: QRCode.SettingsKey.cornerRadiusFraction) {
			for radius in [0.0, 0.43, 1.0] {
				XCTAssertTrue(pair.actual.setSettingValue(radius, forKey: QRCode.SettingsKey.cornerRadiusFraction))
				XCTAssertTrue(pair.reference.setSettingValue(radius, forKey: QRCode.SettingsKey.cornerRadiusFraction))
				let insets = pair.actual.supportsSettingValue(forKey: QRCode.SettingsKey.insetFraction) ? [0.0, 0.27, 1.0] : [0.0]
				for inset in insets {
					if pair.actual.supportsSettingValue(forKey: QRCode.SettingsKey.insetFraction) {
						XCTAssertTrue(pair.actual.setSettingValue(inset, forKey: QRCode.SettingsKey.insetFraction))
						XCTAssertTrue(pair.reference.setSettingValue(inset, forKey: QRCode.SettingsKey.insetFraction))
					}
					for count in [0, 1, 63, 64, 65, 127, 128, 129, 169] {
						try check(pair, matrix: matrix(dimension: 13, activeCount: count))
					}
				}
			}
		}
	}

	private func check(_ pair: Pair, matrix: BoolMatrix,
		size: CGSize = CGSize(width: 197.25, height: 153.75), file: StaticString = #filePath, line: UInt = #line) throws {
		try autoreleasepool {
			let expected = pair.reference.generatePath(from: matrix, size: size)
			let actual = pair.actual.generatePath(from: matrix, size: size)
			let label = "\(pair.actual.name), dimension \(matrix.dimension), settings \(pair.actual.settings()), cells \(matrix.flattened)"
			let wanted = elements(expected)
			let got = elements(actual)
			XCTAssertEqual(got.count, wanted.count, label, file: file, line: line)
			for (index, pair) in zip(got, wanted).enumerated() {
				let matches = pair.0.type == pair.1.type && pair.0.points.count == pair.1.points.count
					&& zip(pair.0.points, pair.1.points).allSatisfy {
						abs($0.x - $1.x) <= 1e-10 && abs($0.y - $1.y) <= 1e-10
					}
				if !matches { XCTFail("\(label): element \(index) differs", file: file, line: line); break }
			}
			XCTAssertPathStateEqual(actual, expected, label: label, file: file, line: line)
			XCTAssertEqual(try raster(actual, size: size), try raster(expected, size: size), label, file: file, line: line)
		}
	}

	/// Spread active cells across rows, include the four corners, and leave gaps between them.
	private func matrix(dimension: Int, activeCount: Int) -> BoolMatrix {
		let result = BoolMatrix(dimension: dimension)
		let cellCount = dimension * dimension
		let corners = [0, dimension - 1, cellCount - dimension, cellCount - 1]
		var visited: Set<Int> = []
		let indices = (corners + (0 ..< cellCount).map { ($0 * 37) % cellCount })
			.filter { visited.insert($0).inserted }
		for index in indices.prefix(activeCount) {
			result[index / dimension, index % dimension] = true
		}
		XCTAssertEqual(result.flattened.filter { $0 }.count, activeCount)
		return result
	}

	private struct Element: Equatable {
		let type: CGPathElementType
		let points: [CGPoint]
	}

	private func elements(_ path: CGPath) -> [Element] {
		var result: [Element] = []
		path.applyWithBlockSafe { pointer in
			let element = pointer.pointee
			let count: Int
			switch element.type {
			case .moveToPoint, .addLineToPoint: count = 1
			case .addQuadCurveToPoint: count = 2
			case .addCurveToPoint: count = 3
			case .closeSubpath: count = 0
			@unknown default: XCTFail("Unexpected path element"); count = 0
			}
			result.append(Element(type: element.type, points: Array(UnsafeBufferPointer(start: element.points, count: count))))
		}
		return result
	}

	private func raster(_ path: CGPath, size: CGSize) throws -> Data {
		let padding = 20
		let width = Int(ceil(size.width)) + 2 * padding
		let height = Int(ceil(size.height)) + 2 * padding
		var bytes = [UInt8](repeating: 0, count: width * height * 4)
		try bytes.withUnsafeMutableBytes { buffer in
			let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
				bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
			context.setFillColor(CGColor(gray: 1, alpha: 1))
			context.fill(CGRect(x: 0, y: 0, width: width, height: height))
			context.translateBy(x: CGFloat(padding), y: CGFloat(padding))
			context.setFillColor(CGColor(red: 0.15, green: 0.35, blue: 0.7, alpha: 0.65))
			context.addPath(path)
			context.fillPath()
		}
		return Data(bytes)
	}
}
