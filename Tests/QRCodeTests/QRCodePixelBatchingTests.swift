import CoreGraphics
import Foundation
import XCTest
@testable import QRCode

final class QRCodePixelBatchingTests: XCTestCase {

	private typealias Generator = QRCode.PixelShape.CommonPixelGenerator

	func testDenseMatricesAndSingleCellIntegrationRaster() throws {
		let input = matrix(dimension: 13, activeCount: 169)
		let size = CGSize(width: 197.25, height: 153.75)
		for type in Generator.PixelType.allCases {
			let generator = Generator(pixelType: type)
			try check(generator, matrix: input, size: size)
			XCTAssertEqual(try raster(generator.generatePath(from: input, size: size), size: size),
				try raster(unbatchedPath(generator, matrix: input, size: size), size: size), type.rawValue)
		}
	}

	func testEmptyAndSingleModuleMatrices() throws {
		for type in Generator.PixelType.allCases {
			for dimension in [0, 1, 9] {
				try check(Generator(pixelType: type), matrix: BoolMatrix(dimension: dimension))
			}
			try check(Generator(pixelType: type), matrix: matrix(dimension: 1, activeCount: 1))
		}
	}

	func testEveryStyleAcrossBatchBoundaries() throws {
		for type in Generator.PixelType.allCases {
			for dimension in [12, 13] {
				for count in [63, 64, 65, 127, 128, 129] {
					let size = dimension == 12
						? CGSize(width: 197.25, height: 153.75)
						: CGSize(width: 153.75, height: 197.25)
					try check(Generator(pixelType: type, cornerRadiusFraction: 0.65),
						matrix: matrix(dimension: dimension, activeCount: count), size: size)
				}
			}
		}
	}

	func testCustomAndStatefulSettings() throws {
		let input = matrix(dimension: 17, activeCount: 193)
		for type in Generator.PixelType.allCases {
			let generators = [
				Generator(pixelType: type, cornerRadiusFraction: 0.43, insetFraction: 0.27, rotationFraction: -0.13),
				Generator(pixelType: type, cornerRadiusFraction: 1, insetFraction: 1, rotationFraction: 1),
				Generator(pixelType: type, cornerRadiusFraction: 0.9,
					insetGenerator: QRCode.PixelInset.Random(), insetFraction: 0.82,
					rotationGenerator: QRCode.PixelRotation.Random(), rotationFraction: -0.74),
				Generator(pixelType: type, cornerRadiusFraction: 0.3,
					insetGenerator: QRCode.PixelInset.Punch(), insetFraction: 0.6,
					rotationGenerator: QRCode.PixelRotation.VWave(), rotationFraction: -1),
			]
			for generator in generators {
				// Reuse the same instance: state must reset for a new render, not at batch boundaries.
				try check(generator, matrix: input)
				try check(generator, matrix: input)
			}
		}
	}

	private func check(_ generator: Generator, matrix: BoolMatrix,
		size: CGSize = CGSize(width: 197.25, height: 153.75), file: StaticString = #filePath, line: UInt = #line) throws {
		let native = QRCode.PixelShape.NativeCommonPixelGenerator(
			pixelType: QRCode.PixelShape.NativeCommonPixelGenerator.PixelType(rawValue: generator.pixelType.rawValue)!,
			cornerRadiusFraction: generator.cornerRadiusFraction,
			insetGenerator: generator.insetGenerator.copyInsetGenerator(), insetFraction: generator.insetFraction,
			rotationGenerator: generator.rotationGenerator.copyRotationGenerator(), rotationFraction: generator.rotationFraction)
		let expected = native.generatePath(from: matrix, size: size)
		let actual = generator.generatePath(from: matrix, size: size)
		let label = "\(generator.pixelType), dimension \(matrix.dimension), active \(matrix.flattened.filter { $0 }.count), "
			+ "inset \(generator.insetGenerator.name)/\(generator.insetFraction), "
			+ "rotation \(generator.rotationGenerator.name)/\(generator.rotationFraction)"
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

	/// Reference accumulation: one active module per call, at its original coordinates and size.
	/// This deliberately reuses the geometry code but never exercises a full batch. The reference
	/// is checked against the original unbatched implementation before the production change.
	/// Evaluate stateful/spatial settings on the complete matrix, then fix their values per module.
	private func unbatchedPath(_ generator: Generator, matrix: BoolMatrix, size: CGSize) -> CGPath {
		let inset = generator.insetGenerator.copyInsetGenerator()
		let rotation = generator.rotationGenerator.copyRotationGenerator()
		inset.reset()
		rotation.reset()
		let single = Generator(pixelType: generator.pixelType, cornerRadiusFraction: generator.cornerRadiusFraction)
		let oneCell = BoolMatrix(dimension: matrix.dimension)
		let result = CGMutablePath()
		for row in 0 ..< matrix.dimension {
			for column in 0 ..< matrix.dimension where matrix[row, column] {
				single.insetFraction = inset.insetValue(for: matrix, row: row, column: column,
					insetFraction: generator.insetFraction)
				single.rotationFraction = rotation.rotationValue(for: matrix, row: row, column: column,
					rotationFraction: generator.rotationFraction)
				oneCell[row, column] = true
				result.addPath(single.generatePath(from: oneCell, size: size))
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
