// Frozen unbatched reference; geometry and traversal copied before optimization.
// Original Sources/QRCode/styles/data/QRCodePixelShapeRoundedEndIndent.swift
// SHA-256: 996a0903db53b7a30f1d3160dd7b6803ccb6df3d93c467a0721abace15cd84ea
@testable import QRCode

//
//  Copyright © 2026 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import CoreGraphics
import Foundation

extension QRCodeUnbatchedReference {
	class RoundedEndIndent: NSObject, QRCodeUnbatchedGenerator {
		var emittedPathCount = 0
		/// The generator name
		static let Name = "roundedEndIndent"
		/// The generator title
		static var Title: String { "Rounded end indent" }

		/// This pupil generator can be used when generating eye and pupil shapes
		var canGenerateEyeAndPupilShapes: Bool { true }

		// The default radius for the curved edges
		static let DefaultCornerRadius: CGFloat = 0.65
		// Should we draw inner corners on the shape
		static let DefaultHasInnerCorners: Bool = false

		/// Create an instance of this path generator with the specified settings
		static func Create(_ settings: [String: Any]?) -> any QRCodePixelShapeGenerator {
			let radius = DoubleValue(settings?[QRCode.SettingsKey.cornerRadiusFraction]) ?? Self.DefaultCornerRadius
			let hasInnerCorners = BoolValue(settings?[QRCode.SettingsKey.hasInnerCorners]) ?? Self.DefaultHasInnerCorners
			return RoundedEndIndent(cornerRadiusFraction: radius, hasInnerCorners: hasInnerCorners)
		}

		// The template pixel generator size is 10x10
		static let DefaultSize = CGSize(width: 10, height: 10)
		static let DefaultRect = CGRect(origin: .zero, size: DefaultSize)

		private let innerRadius: Double = 5.0 / 3.0

		private var actualRadiusSize = CGSize(width: 3, height: 3)
		private var actualRadius: CGFloat = 3

		private func cornerRadiusChanged() {
			self.actualRadius = self._cornerRadius * 5
			self.actualRadiusSize = CGSize(width: self.actualRadius, height: self.actualRadius)
		}

		// The radius as relates to the 10x10 pixel size
		private var _cornerRadius: CGFloat = DefaultCornerRadius {
			didSet {
				self.cornerRadiusChanged()
			}
		}

		/// The corner radius fraction (0 ... 1)
		var cornerRadiusFraction: CGFloat {
			get { self._cornerRadius }
			set { self._cornerRadius = newValue.clamped(to: 0 ... 1) }
		}

		/// Do we draw the inner corners when drawing path?
		var hasInnerCorners: Bool = true

		/// Create
		init(
			cornerRadiusFraction: CGFloat = QRCodeUnbatchedReference.RoundedEndIndent.DefaultCornerRadius,
			hasInnerCorners: Bool = QRCodeUnbatchedReference.RoundedEndIndent.DefaultHasInnerCorners
		) {
			self._cornerRadius = cornerRadiusFraction.clamped(to: 0 ... 1)
			self.hasInnerCorners = hasInnerCorners
			super.init()
			self.cornerRadiusChanged()
		}

		/// Make a copy of the shape
		func copyShape() -> any QRCodePixelShapeGenerator {
			RoundedEndIndent(
				cornerRadiusFraction: self.cornerRadiusFraction,
				hasInnerCorners: self.hasInnerCorners
			)
		}

		/// Reset the generator back to defaults
		func reset() {
			self._cornerRadius = QRCodeUnbatchedReference.RoundedEndIndent.DefaultCornerRadius
			self.hasInnerCorners = QRCodeUnbatchedReference.RoundedEndIndent.DefaultHasInnerCorners
			self.cornerRadiusChanged()
		}
	}
}

extension QRCodeUnbatchedReference.RoundedEndIndent {
	/// Generate a CGPath from the matrix contents
	/// - Parameters:
	///   - matrix: The matrix to generate
	///   - size: The size of the resulting CGPath
	/// - Returns: A path
	func generatePath(from matrix: BoolMatrix, size: CGSize) -> CGPath {
		let dx = size.width / CGFloat(matrix.dimension)
		let dy = size.height / CGFloat(matrix.dimension)
		let dm = min(dx, dy)

		let xoff = (size.width - (CGFloat(matrix.dimension) * dm)) / 2.0
		let yoff = (size.height - (CGFloat(matrix.dimension) * dm)) / 2.0

		// The scale required to convert our template paths to output path size
		let w = QRCodeUnbatchedReference.RoundedEndIndent.DefaultSize.width
		let scaleTransform = CGAffineTransform(scaleX: dm / w, y: dm / w)

		let path = QRCodeUnbatchedReference.Path()

		for row in 0 ..< matrix.dimension {
			for col in 0 ..< matrix.dimension {

				let hasLeft: Bool = {
					if col == 0 { return false }
					return (col - 1) >= 0 ? matrix[row, col - 1] : false
				}()
				let hasRight: Bool = {
					if col == (matrix.dimension - 1) { return false }
					return (col + 1) < matrix.dimension ? matrix[row, col + 1] : false
				}()
				let hasTop: Bool = {
					if row == 0 { return false }
					return (row - 1) >= 0 ? matrix[row - 1, col] : false
				}()
				let hasBottom: Bool = {
					if row == (matrix.dimension - 1) { return false }
					return (row + 1) < matrix.dimension ? matrix[row + 1, col] : false
				}()

				let translate = CGAffineTransform(translationX: CGFloat(col) * dm + xoff, y: CGFloat(row) * dm + yoff)

				guard matrix[row, col] == true else {
					guard hasInnerCorners == true else {
						continue
					}

					let hasTopLeft: Bool = {
						if col == 0 || row == 0 { return false }
						return ((col - 1) >= 0 && (row - 1) >= 0) ? matrix[row - 1, col - 1] : false
					}()
					let hasTopRight: Bool = {
						if col == (matrix.dimension - 1) || row == 0 { return false }
						return ((col + 1) >= 0 && (row - 1) >= 0) ? matrix[row - 1, col + 1] : false
					}()
					let hasBottomLeft: Bool = {
						if col == 0 || row == (matrix.dimension - 1) { return false }
						return ((col - 1) >= 0 && (row + 1) >= 0) ? matrix[row + 1, col - 1] : false
					}()
					let hasBottomRight: Bool = {
						if col == (matrix.dimension - 1) || row == (matrix.dimension - 1) { return false }
						return ((col + 1) >= 0 && (row + 1) >= 0) ? matrix[row + 1, col + 1] : false
					}()

					if hasLeft, hasTop, hasTopLeft {
						path.addPath(
							self.templateRoundTopLeft(),
							transform: scaleTransform.concatenating(translate)
						)
					}
					if hasRight, hasTop, hasTopRight {
						path.addPath(
							self.templateRoundTopRight(),
							transform: scaleTransform.concatenating(translate)
						)
					}
					if hasLeft, hasBottom, hasBottomLeft {
						path.addPath(
							self.templateRoundBottomLeft(),
							transform: scaleTransform.concatenating(translate)
						)
					}
					if hasRight, hasBottom, hasBottomRight {
						path.addPath(
							self.templateRoundBottomRight(),
							transform: scaleTransform.concatenating(translate)
						)
					}
					continue
				}

				if !hasLeft, !hasRight, !hasTop, !hasBottom {
					path.addPath(
						self.templateCircle(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if hasLeft, !hasRight, !hasTop, !hasBottom {
					path.addPath(
						self.templateRoundRight(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if !hasLeft, hasRight, !hasTop, !hasBottom {
					path.addPath(
						self.templateRoundLeft(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if !hasLeft, !hasRight, hasTop, !hasBottom {
					path.addPath(
						self.templateRoundBottom(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if !hasLeft, !hasRight, !hasTop, hasBottom {
					path.addPath(
						self.templateRoundTop(),
						transform: scaleTransform.concatenating(translate)
					)
				}

				else if hasLeft, hasTop, !hasRight, !hasBottom {
					path.addPath(
						self.templateBottomRight(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if !hasLeft, hasTop, hasRight, !hasBottom {
					path.addPath(
						self.templateBottomLeft(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if hasLeft, !hasTop, !hasRight, hasBottom {
					path.addPath(
						self.templateTopRight(),
						transform: scaleTransform.concatenating(translate)
					)
				}
				else if !hasLeft, !hasTop, hasRight, hasBottom {
					path.addPath(
						self.templateTopLeft(),
						transform: scaleTransform.concatenating(translate)
					)
				}

				else {
					path.addPath(
						QRCodeUnbatchedReference.RoundedEndIndent.templateSquare,
						transform: scaleTransform.concatenating(translate)
					)
				}
			}
		}
		self.emittedPathCount = path.count
		return path.result
	}
}

// MARK: - Template shapes

private extension QRCodeUnbatchedReference.RoundedEndIndent {
	private static let templateSquare = CGPath(rect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect, transform: nil)

	private func templateCircle() -> CGPath {
		CGPath(
			roundedRect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect,
			cornerWidth: actualRadius, cornerHeight: actualRadius,
			transform: nil
		)
	}

	private func templateRoundTop() -> CGPath {
		let rectanglePath = CGMutablePath()
		rectanglePath.move(to: CGPoint(x: 0, y: 10))
		rectanglePath.line(to: CGPoint(x: 10, y: 10))
		rectanglePath.line(to: CGPoint(x: 10, y: 0))
		rectanglePath.curve(to: CGPoint(x: 5, y: 2), controlPoint1: CGPoint(x: 10, y: 0), controlPoint2: CGPoint(x: 9, y: 2))
		rectanglePath.curve(to: CGPoint(x: 0, y: 0), controlPoint1: CGPoint(x: 1, y: 2), controlPoint2: CGPoint(x: 0, y: 0))
		rectanglePath.line(to: CGPoint(x: 0, y: 10))
		rectanglePath.close()
		return rectanglePath
	}

	private func templateRoundRight() -> CGPath {
		//// Rectangle Drawing
		let rectanglePath = CGMutablePath()
		rectanglePath.move(to: CGPoint(x: 0, y: 0))
		rectanglePath.line(to: CGPoint(x: 10, y: 0))
		rectanglePath.curve(to: CGPoint(x: 8, y: 5), controlPoint1: CGPoint(x: 10, y: 0), controlPoint2: CGPoint(x: 8, y: 1))
		rectanglePath.curve(to: CGPoint(x: 10, y: 10), controlPoint1: CGPoint(x: 8, y: 9), controlPoint2: CGPoint(x: 10, y: 10))
		rectanglePath.line(to: CGPoint(x: 0, y: 10))
		rectanglePath.line(to: CGPoint(x: 0, y: 0))
		rectanglePath.close()
		return rectanglePath
	}

	private func templateRoundBottom() -> CGPath {
		let rectanglePath = CGMutablePath()
		rectanglePath.move(to: CGPoint(x: 0, y: 0))
		rectanglePath.line(to: CGPoint(x: 10, y: 0))
		rectanglePath.line(to: CGPoint(x: 10, y: 10))
		rectanglePath.curve(to: CGPoint(x: 5, y: 8), controlPoint1: CGPoint(x: 10, y: 10), controlPoint2: CGPoint(x: 9, y: 8))
		rectanglePath.curve(to: CGPoint(x: 0, y: 10), controlPoint1: CGPoint(x: 1, y: 8), controlPoint2: CGPoint(x: 0, y: 10))
		rectanglePath.line(to: CGPoint(x: 0, y: 0))
		rectanglePath.close()
		return rectanglePath
	}

	private func templateRoundLeft() -> CGPath {
		let rectanglePath = CGMutablePath()
		rectanglePath.move(to: CGPoint(x: 10, y: 0))
		rectanglePath.line(to: CGPoint(x: 0, y: 0))
		rectanglePath.curve(to: CGPoint(x: 2, y: 5), controlPoint1: CGPoint(x: 0, y: 0), controlPoint2: CGPoint(x: 2, y: 1))
		rectanglePath.curve(to: CGPoint(x: 0, y: 10), controlPoint1: CGPoint(x: 2, y: 9), controlPoint2: CGPoint(x: 0, y: 10))
		rectanglePath.line(to: CGPoint(x: 10, y: 10))
		rectanglePath.line(to: CGPoint(x: 10, y: 0))
		rectanglePath.close()
		return rectanglePath
	}

	private func templateBottomRight() -> CGPath {
		CGPath.RoundedRect(
			rect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect,
			bottomRightRadius: actualRadiusSize
		)
	}

	private func templateTopRight() -> CGPath {
		CGPath.RoundedRect(
			rect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect,
			topRightRadius: actualRadiusSize
		)
	}

	private func templateTopLeft() -> CGPath {
		CGPath.RoundedRect(
			rect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect,
			topLeftRadius: actualRadiusSize
		)
	}

	private func templateBottomLeft() -> CGPath {
		CGPath.RoundedRect(
			rect: QRCodeUnbatchedReference.RoundedEndIndent.DefaultRect,
			bottomLeftRadius: actualRadiusSize
		)
	}
}

// MARK: - Template corner shapes

private extension QRCodeUnbatchedReference.RoundedEndIndent {
	private func templateRoundTopLeft() -> CGPath {
		let tlPath = CGMutablePath()
		let fr = innerRadius * cornerRadiusFraction
		tlPath.move(to: CGPoint(x: fr, y: 0))
		tlPath.line(to: CGPoint(x: 0, y: 0))
		tlPath.curve(to: CGPoint(x: 0, y: fr), controlPoint1: CGPoint(x: 0, y: 0), controlPoint2: CGPoint(x: 0, y: fr / 2))
		tlPath.curve(to: CGPoint(x: fr, y: 0), controlPoint1: CGPoint(x: 0, y: fr / 2), controlPoint2: CGPoint(x: fr / 2, y: 0))
		tlPath.close()
		return tlPath
	}

	private func templateRoundTopRight() -> CGPath {
		let trPath = CGMutablePath()
		trPath.addPath(
			templateRoundTopLeft(),
			transform:
				CGAffineTransform(scaleX: -1, y: 1)
					.concatenating(
						CGAffineTransform(translationX: 10, y: 0)))
		return trPath
	}

	private func templateRoundBottomLeft() -> CGPath {
		let blPath = CGMutablePath()
		blPath.addPath(
			templateRoundTopLeft(),
			transform:
				CGAffineTransform(scaleX: 1, y: -1)
					.concatenating(.init(translationX: 0, y: 10)))
		return blPath
	}

	private func templateRoundBottomRight() -> CGPath {
		let brPath = CGMutablePath()
		brPath.addPath(
			templateRoundTopLeft(),
			transform:
				CGAffineTransform(scaleX: -1, y: -1)
					.concatenating(.init(translationX: 10, y: 10)))
		return brPath
	}

}

// MARK: - Settings

extension QRCodeUnbatchedReference.RoundedEndIndent {
	/// Does the shape generator support setting values for a particular key?
	func supportsSettingValue(forKey key: String) -> Bool {
		return key == QRCode.SettingsKey.cornerRadiusFraction
			 || key == QRCode.SettingsKey.hasInnerCorners
	}

	/// Returns a storable representation of the shape handler
	func settings() -> [String: Any] {
		return [
			QRCode.SettingsKey.cornerRadiusFraction: self._cornerRadius,
			QRCode.SettingsKey.hasInnerCorners: self.hasInnerCorners
		]
	}

	/// Set a configuration value for a particular setting string
	func setSettingValue(_ value: Any?, forKey key: String) -> Bool {
		if key == QRCode.SettingsKey.cornerRadiusFraction {
			guard let v = value else {
				self.cornerRadiusFraction = Self.DefaultCornerRadius
				return true
			}
			guard let v = DoubleValue(v) else { return false }
			self.cornerRadiusFraction = v
			return true
		}
		if key == QRCode.SettingsKey.hasInnerCorners {
			guard let v = value else {
				self.hasInnerCorners = Self.DefaultHasInnerCorners
				return true
			}
			guard let v = BoolValue(v) else { return false }
			self.hasInnerCorners = v
			return true
		}
		return false
	}
}


// MARK: - Pixel creation conveniences


