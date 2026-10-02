import Foundation
import Vision
import ImageIO

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let src = CGImageSourceCreateWithURL(url, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("\(path) LOADFAIL"); continue }
    let req = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: img, options: [:])
    try? handler.perform([req])
    let faces = (req.results ?? []).sorted { $0.boundingBox.width > $1.boundingBox.width }
    let name = (path as NSString).lastPathComponent
    if let f = faces.first {
        let b = f.boundingBox
        // Vision origin is bottom-left; report centre x, centre y from top, width — all as fractions of the image.
        let cx = b.midX, cy = 1 - b.midY, w = b.width
        print(String(format: "%@ fx=%.3f fy=%.3f fw=%.3f n=%d", name, cx, cy, w, faces.count))
    } else {
        print("\(name) NOFACE")
    }
}
