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

internal extension CGMutablePath {
	/// Append pixel-template elements without rescanning accumulated bounds.
	/// Templates and the destination must not end in a pending move-only subpath.
	/// Start a new subpath to extend the result; native append has different internal
	/// continuation bookkeeping. This helper is only for pixel-template accumulation.
	/// Expand primitives before transforming their elements to preserve native curve
	/// coordinates. Individual element additions also retain control-point bounds.
	func addPixelPath(_ path: CGPath, transform: CGAffineTransform) {
		// Native append into an empty destination is bounded by this one template and
		// preserves CoreGraphics' initial primitive representation. Identity needs no work.
		if isEmpty || transform.isIdentity {
			addPath(path, transform: transform)
			return
		}
		path.applyWithBlock { pointer in
			let element = pointer.pointee
			switch element.type {
			case .moveToPoint:
				self.move(to: element.points[0], transform: transform)
			case .addLineToPoint:
				self.addLine(to: element.points[0], transform: transform)
			case .addQuadCurveToPoint:
				self.addQuadCurve(to: element.points[1], control: element.points[0], transform: transform)
			case .addCurveToPoint:
				self.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1], transform: transform)
			case .closeSubpath:
				self.closeSubpath()
			@unknown default:
				preconditionFailure("Unexpected CoreGraphics path element")
			}
		}
	}
}
