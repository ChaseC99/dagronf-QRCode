import CoreGraphics
import Foundation
import XCTest
@testable import QRCode

#if !os(watchOS)
/// Opt-in measurements: ordinary test runs skip this potentially slow suite.
final class QRCodePerformanceTests: XCTestCase {

	func testRenderBaseline() throws {
		let environment = ProcessInfo.processInfo.environment
		guard environment["QRCODE_BENCHMARK"] == "1" else {
			throw XCTSkip("Run scripts/benchmark-render.sh to collect render timings.")
		}
		let sampleCount = try XCTUnwrap(Int(environment["QRCODE_BENCHMARK_SAMPLES"] ?? "5"))
		guard sampleCount > 0 else {
			throw NSError(domain: "QRCodeBenchmark", code: 1, userInfo: [
				NSLocalizedDescriptionKey: "QRCODE_BENCHMARK_SAMPLES must be positive",
			])
		}
		let outputPath = try XCTUnwrap(environment["QRCODE_BENCHMARK_OUTPUT"])
		let startedAt = ISO8601DateFormatter().string(from: Date())
		let targetDimension = 720
		let additionalQuietZonePixels = 4
		let fixtures = [
			("small", "https://example.com/"),
			("medium", Self.vcard(noteRepeats: 20)),
			("large", Self.vcard(noteRepeats: 95)),
		]
		// Include every registered style so the report cannot silently omit new shapes.
		let styles = QRCodePixelShapeFactory.shared.all()
		var fixtureRecords: [[String: Any]] = []
		var results: [[String: Any]] = []

		for (fixtureName, payload) in fixtures {
			// Encoding, masking, sizing, and design setup are outside all timed intervals.
			let code = try QRCode(utf8String: payload, errorCorrection: .high, engine: QRCodeEngineCoreImage())
			let matrix = code.boolMatrix.maskingQREyes(inverted: false)
			let pixelsPerModule = max(1, targetDimension / (code.cellDimension + 2 * additionalQuietZonePixels))
			let imageDimension = pixelsPerModule * (code.cellDimension + 2 * additionalQuietZonePixels)
			let pathDimension = pixelsPerModule * code.cellDimension
			let pathSize = CGSize(width: pathDimension, height: pathDimension)
			fixtureRecords.append([
				"name": fixtureName, "payload": payload, "utf8Bytes": payload.utf8.count,
				"matrixDimension": matrix.dimension,
				"activeDataModules": matrix.flattened.filter { $0 }.count,
				"maskedMatrixFNV1a64": Self.fingerprint(matrix.flattened),
				"pixelsPerModule": pixelsPerModule, "pathDimension": pathDimension,
				"imageWidth": imageDimension, "imageHeight": imageDimension,
			])

			for generator in styles {
				let design = QRCode.Design(
					foregroundColor: CGColor(gray: 0, alpha: 1),
					backgroundColor: CGColor(gray: 1, alpha: 1)
				)
				design.additionalQuietZonePixels = UInt(additionalQuietZonePixels)
				design.shape.onPixels = generator
				let pathOperation = { generator.generatePath(from: matrix, size: pathSize) }
				let imageOperation = { try code.cgImage(dimension: imageDimension, design: design) }
				let validatePath: (CGPath) -> Void = { XCTAssertFalse($0.isEmpty) }
				let validateImage: (CGImage) -> Void = {
					XCTAssertEqual($0.width, imageDimension)
					XCTAssertEqual($0.height, imageDimension)
				}

				// One warm-up per operation. Each result is validated and released outside timing.
				_ = Self.time(pathOperation, validate: validatePath)
				_ = try Self.time(imageOperation, validate: validateImage)
				var pathSamples: [Double] = []
				var imageSamples: [Double] = []
				for sample in 0 ..< sampleCount {
					// Alternate the operation order to reduce consistent first/second bias.
					if sample.isMultiple(of: 2) {
						pathSamples.append(Self.time(pathOperation, validate: validatePath))
						imageSamples.append(try Self.time(imageOperation, validate: validateImage))
					}
					else {
						imageSamples.append(try Self.time(imageOperation, validate: validateImage))
						pathSamples.append(Self.time(pathOperation, validate: validatePath))
					}
				}
				results.append([
					"fixture": fixtureName, "style": generator.name, "styleTitle": generator.title,
					"pixelSettings": generator.settings(),
					"path": Self.statistics(pathSamples), "image": Self.statistics(imageSamples),
				])
				print(String(format: "BENCHMARK %@ / %@: path %.3f ms, image %.3f ms (median, n=%d)",
					fixtureName, generator.name, Self.median(pathSamples), Self.median(imageSamples), sampleCount))
				fflush(stdout)
			}
		}

		#if DEBUG
		let configuration = "debug"
		#else
		let configuration = "release"
		#endif
		var metadata: [String: Any] = [
			"startedAt": startedAt,
			"finishedAt": ISO8601DateFormatter().string(from: Date()),
			"configuration": configuration,
			"os": ProcessInfo.processInfo.operatingSystemVersionString,
			"processorCount": ProcessInfo.processInfo.processorCount,
			"physicalMemoryBytes": ProcessInfo.processInfo.physicalMemory,
		]
		for key in ["REVISION", "SOURCE_TREE", "SOURCE_DIFF_SHA256", "WORKTREE_STATUS", "HARNESS_SHA256",
			"SWIFT_VERSION", "XCODE_VERSION", "HARDWARE", "ARCHITECTURE", "SOURCE_STATE_SHA256"] {
			metadata[key.lowercased()] = environment["QRCODE_BENCHMARK_" + key] ?? "not supplied"
		}
		// Read after SwiftPM has resolved dependencies, including on a fresh checkout.
		if let root = environment["QRCODE_BENCHMARK_ROOT"] {
			let resolvedURL = URL(fileURLWithPath: root).appendingPathComponent("Package.resolved")
			metadata["packageResolved"] = try JSONSerialization.jsonObject(with: Data(contentsOf: resolvedURL))
		}
		let report: [String: Any] = [
			"schemaVersion": 1, "metadata": metadata,
			"method": [
				"engine": "coreimage", "errorCorrection": "high", "targetDimension": targetDimension,
				"additionalQuietZonePixels": additionalQuietZonePixels, "samples": sampleCount, "warmups": 1,
				"styles": styles.map { $0.name },
				"clock": "DispatchTime.uptimeNanoseconds", "unit": "milliseconds",
				"foreground": "black", "background": "white", "logo": "none",
				"eyes": "square", "pupil": "default for square eye",
				"path": "Pixel generator only; pre-masked data modules, excluding eyes and quiet zone",
				"image": "QRCode.cgImage; includes context allocation, masking, all paths, drawing, and makeImage",
			],
			"fixtures": fixtureRecords, "results": results,
		]
		let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
		try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
		print("BENCHMARK report: \(outputPath)")
	}

	private static func vcard(noteRepeats: Int) -> String {
		"BEGIN:VCARD\r\nVERSION:3.0\r\nN:Example;Alex;;;\r\nFN:Alex Example\r\nNOTE:"
			+ String(repeating: "abcdefghij ", count: noteRepeats)
			+ "\r\nEND:VCARD"
	}

	/// Keep the returned object alive until after the clock stops; do not time validation or destruction.
	@inline(never) private static func time<T>(_ operation: () throws -> T, validate: (T) -> Void) rethrows -> Double {
		try autoreleasepool {
			let start = DispatchTime.now().uptimeNanoseconds
			let result = try operation()
			let end = DispatchTime.now().uptimeNanoseconds
			validate(result)
			return Double(end - start) / 1_000_000
		}
	}

	private static func median(_ samples: [Double]) -> Double {
		let sorted = samples.sorted()
		let middle = sorted.count / 2
		return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
	}

	private static func statistics(_ samples: [Double]) -> [String: Any] {
		let mean = samples.reduce(0, +) / Double(samples.count)
		let variance = samples.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(samples.count)
		return [
			"samplesMs": samples, "medianMs": median(samples), "minMs": samples.min()!,
			"maxMs": samples.max()!, "meanMs": mean, "standardDeviationMs": sqrt(variance),
		]
	}

	/// A stable identity check for the row-major masked matrix (each Bool encoded as 0 or 1).
	private static func fingerprint(_ cells: [Bool]) -> String {
		let hash = cells.reduce(UInt64(14695981039346656037)) { ($0 ^ ($1 ? 1 : 0)) &* 1099511628211 }
		return String(format: "%016llx", hash)
	}
}
#endif
