import XCTest
import UIKit
@testable import Gowith

/// 图片保存前的统一压缩（P1：相机原图可达 3–5MB/张）。
final class ImageCompressionTests: XCTestCase {
    private func solidImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testNormalizedJPEGCapsLongEdgeTo1024() throws {
        let raw = try XCTUnwrap(solidImage(width: 2400, height: 1200).jpegData(compressionQuality: 0.82))

        let normalized = try XCTUnwrap(LocalImageStore.normalizedJPEGData(from: raw))
        let scaled = try XCTUnwrap(UIImage(data: normalized))

        XCTAssertEqual(max(scaled.size.width, scaled.size.height) * scaled.scale, 1024, accuracy: 2,
                       "最长边应压缩到 1024px")
    }

    func testNormalizedJPEGDoesNotUpscaleSmallImages() throws {
        let raw = try XCTUnwrap(solidImage(width: 800, height: 600).jpegData(compressionQuality: 0.82))

        let normalized = try XCTUnwrap(LocalImageStore.normalizedJPEGData(from: raw))
        let scaled = try XCTUnwrap(UIImage(data: normalized))

        XCTAssertEqual(max(scaled.size.width, scaled.size.height) * scaled.scale, 800, accuracy: 2,
                       "小于 1024px 的图片不应被放大")
    }

    func testNormalizedJPEGFallsBackToOriginalOnInvalidData() {
        let garbage = Data("not an image".utf8)
        XCTAssertEqual(LocalImageStore.normalizedJPEGData(from: garbage), garbage,
                       "无法解析的数据应原样返回，由上层兜底")
    }
}
