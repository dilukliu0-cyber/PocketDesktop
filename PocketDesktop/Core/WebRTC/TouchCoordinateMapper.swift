import Foundation
import CoreGraphics

public struct DesktopScreenDimension {
    public let width: CGFloat
    public let height: CGFloat
    
    public init(width: CGFloat = 1920, height: CGFloat = 1080) {
        self.width = width
        self.height = height
    }
}

public struct TouchCoordinateMapper {
    public let desktopSize: DesktopScreenDimension
    
    public init(desktopSize: DesktopScreenDimension = DesktopScreenDimension()) {
        self.desktopSize = desktopSize
    }
    
    /// Converts a touch point inside an iPhone view container into native desktop pixel coordinates.
    /// Handles AspectFit letterboxing/pillarboxing, zoom scale, and pan offset.
    public func map(
        touchPoint: CGPoint,
        viewSize: CGSize,
        zoomScale: CGFloat = 1.0,
        contentOffset: CGPoint = .zero
    ) -> CGPoint? {
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }
        guard desktopSize.width > 0, desktopSize.height > 0 else { return nil }
        
        let desktopAspect = desktopSize.width / desktopSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        var renderWidth: CGFloat
        var renderHeight: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        if viewAspect > desktopAspect {
            // View is wider than desktop -> pillarboxing (bars on left & right)
            renderHeight = viewSize.height
            renderWidth = viewSize.height * desktopAspect
            offsetX = (viewSize.width - renderWidth) / 2.0
        } else {
            // View is taller than desktop -> letterboxing (bars on top & bottom)
            renderWidth = viewSize.width
            renderHeight = viewSize.width / desktopAspect
            offsetY = (viewSize.height - renderHeight) / 2.0
        }
        
        // Adjust for zoom and pan
        let adjustedX = (touchPoint.x - offsetX - contentOffset.x) / zoomScale
        let adjustedY = (touchPoint.y - offsetY - contentOffset.y) / zoomScale
        
        // Check if touch falls within active render area
        guard adjustedX >= 0, adjustedX <= renderWidth,
              adjustedY >= 0, adjustedY <= renderHeight else {
            return nil
        }
        
        // Normalize 0.0 ... 1.0
        let normalizedX = adjustedX / renderWidth
        let normalizedY = adjustedY / renderHeight
        
        // Scale to desktop pixel dimensions
        let desktopX = max(0, min(desktopSize.width, normalizedX * desktopSize.width))
        let desktopY = max(0, min(desktopSize.height, normalizedY * desktopSize.height))
        
        return CGPoint(x: desktopX, y: desktopY)
    }
    
    /// Returns normalized coordinates (0.0 ... 1.0)
    public func mapNormalized(
        touchPoint: CGPoint,
        viewSize: CGSize
    ) -> CGPoint? {
        guard let pixel = map(touchPoint: touchPoint, viewSize: viewSize) else { return nil }
        return CGPoint(x: pixel.x / desktopSize.width, y: pixel.y / desktopSize.height)
    }
}
