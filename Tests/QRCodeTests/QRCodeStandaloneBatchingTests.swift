import CoreGraphics
import Foundation
import XCTest
@testable import QRCode

final class QRCodeStandaloneBatchingTests: XCTestCase {

	func testSingleCellIntegrationRaster() throws {
		let input = matrix(dimension: 13, activeCount: 169)
		let size = CGSize(width: 197.25, height: 153.75)
		for generator in generators {
			XCTAssertEqual(try raster(generator.generatePath(from: input, size: size), size: size),
				try raster(unbatchedPath(generator, matrix: input, size: size), size: size), generator.name)
		}
	}

	private var generators: [QRCodePixelShapeGenerator] {
		[
			QRCode.PixelShape.Grid2x2(), QRCode.PixelShape.Grid3x3(), QRCode.PixelShape.Grid4x4(),
			QRCode.PixelShape.Donut(), QRCode.PixelShape.DiagonalStripes(),
		]
	}

	func testEmptySingleSparseAndDenseMatrices() throws {
		for generator in generators {
			for dimension in [0, 1, 8, 9, 12, 13] {
				try check(generator, matrix: BoolMatrix(dimension: dimension))
				if dimension > 0 {
					for count in Set([1, min(4, dimension * dimension), dimension * dimension]) {
						try check(generator, matrix: matrix(dimension: dimension, activeCount: count))
					}
				}
			}
		}
	}

	func testEveryStyleAcrossBatchBoundaries() throws {
		for generator in generators {
			for dimension in [12, 13] {
				for count in [63, 64, 65, 127, 128, 129] {
					let size = dimension == 12
						? CGSize(width: 197.25, height: 153.75)
						: CGSize(width: 153.75, height: 197.25)
					try check(generator, matrix: matrix(dimension: dimension, activeCount: count), size: size)
				}
			}
		}
	}

	func testTemplateSubpathsStayClosedAndOrdered() throws {
		for (generator, subpaths) in zip(generators, [4, 9, 16, 2, 7]) {
			for count in [1, 64, 65, 128, 129] {
				let input = matrix(dimension: 13, activeCount: count)
				let path = generator.generatePath(from: input, size: CGSize(width: 130, height: 130))
				let commands = elements(path)
				XCTAssertEqual(commands.filter { $0.type == .moveToPoint }.count, subpaths * count, generator.name)
				XCTAssertEqual(commands.filter { $0.type == .closeSubpath }.count, subpaths * count, generator.name)
				XCTAssertEqual(commands.last?.type, .closeSubpath, generator.name)
				try check(generator, matrix: input, size: CGSize(width: 130, height: 130))
			}
		}
	}

	func testDonutHolesWithNonzeroAndEvenOddWinding() throws {
		let generator = QRCode.PixelShape.Donut()
		for count in [1, 63, 64, 65, 127, 128, 129] {
			let input = matrix(dimension: 13, activeCount: count)
			let path = generator.generatePath(from: input, size: CGSize(width: 130, height: 130))
			for row in 0 ..< input.dimension {
				for column in 0 ..< input.dimension {
					let center = CGPoint(x: column * 10 + 5, y: row * 10 + 5)
					let ring = CGPoint(x: column * 10 + 8, y: row * 10 + 5)
					for rule: CGPathFillRule in [.winding, .evenOdd] {
						XCTAssertFalse(path.contains(center, using: rule))
						XCTAssertEqual(path.contains(ring, using: rule), input[row, column])
					}
				}
			}
			try check(generator, matrix: input, size: CGSize(width: 130, height: 130))
		}
	}

	private func check(_ generator: QRCodePixelShapeGenerator, matrix: BoolMatrix,
		size: CGSize = CGSize(width: 197.25, height: 153.75), file: StaticString = #filePath, line: UInt = #line) throws {
		let native: QRCodePixelShapeGenerator
		switch generator.name {
		case "grid2x2": native = QRCodeNativeStandalone.Grid2x2()
		case "grid3x3": native = QRCodeNativeStandalone.Grid3x3()
		case "grid4x4": native = QRCodeNativeStandalone.Grid4x4()
		case "donut": native = QRCodeNativeStandalone.Donut()
		case "diagonalStripes": native = QRCodeNativeStandalone.DiagonalStripes()
		default: fatalError("Missing native reference for \(generator.name)")
		}
		let expected = native.generatePath(from: matrix, size: size)
		let actual = generator.generatePath(from: matrix, size: size)
		let label = "\(generator.name), dimension \(matrix.dimension), active \(matrix.flattened.filter { $0 }.count)"
		let expectedElements = elements(expected)
		let actualElements = elements(actual)
		XCTAssertEqual(actualElements.count, expectedElements.count, label, file: file, line: line)
		for (index, pair) in zip(actualElements, expectedElements).enumerated() {
			XCTAssertEqual(pair.0.type, pair.1.type, "\(label): element \(index)", file: file, line: line)
			XCTAssertEqual(pair.0.points.count, pair.1.points.count, label, file: file, line: line)
			// Core Graphics expands native ellipse/rectangle representations with tiny rounding
			// differences even on the original implementation. Keep structure and raster exact.
			for (actualPoint, expectedPoint) in zip(pair.0.points, pair.1.points) {
				XCTAssertEqual(actualPoint.x, expectedPoint.x, accuracy: 1e-10, label, file: file, line: line)
				XCTAssertEqual(actualPoint.y, expectedPoint.y, accuracy: 1e-10, label, file: file, line: line)
			}
		}
		XCTAssertPathStateEqual(actual, expected, label: label, file: file, line: line)
		XCTAssertEqual(try raster(actual, size: size), try raster(expected, size: size), label, file: file, line: line)
	}

	/// Append one module at a time at its original matrix coordinate. These standalone
	/// styles have no neighbor/state dependence. This shares the unchanged template and
	/// transform code, but never exercises a full production batch. Validated against
	/// the original generators before batching was introduced.
	private func unbatchedPath(_ generator: QRCodePixelShapeGenerator, matrix: BoolMatrix, size: CGSize) -> CGPath {
		let oneCell = BoolMatrix(dimension: matrix.dimension)
		let result = CGMutablePath()
		for row in 0 ..< matrix.dimension {
			for column in 0 ..< matrix.dimension where matrix[row, column] {
				oneCell[row, column] = true
				result.addPath(generator.generatePath(from: oneCell, size: size))
				oneCell[row, column] = false
			}
		}
		return result
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
