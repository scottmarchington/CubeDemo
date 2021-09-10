//
//  ViewController.swift
//  colorcube
//
//  Created by Scott Marchington on 9/10/21.
//

import UIKit

/// Model for our cube
enum CubeFace: CaseIterable {
    enum Constants {
        static let edgeLength: CGFloat = 100
        static let hasText: Bool = true
    }
    
    case front
    case back
    case left
    case right
    case top
    case bottom
    
    var edgeLength: CGFloat { Constants.edgeLength }
    
    var size: CGSize { CGSize(width: edgeLength, height: edgeLength) }
    
    var color: UIColor {
        switch self {
        case .front:
            return .yellow
        case .back:
            return .purple
        case .left:
            return .blue
        case .right:
            return .orange
        case .top:
            return .red
        case .bottom:
            return .green
        }
    }
    
    var text: String? {
        guard Constants.hasText else { return nil }
        switch self {
        case .front: return "1"
        case .back: return "6"
        case .left: return "2"
        case .right: return "5"
        case .top: return "3"
        case .bottom: return "4"
        }
    }
}

class ViewController: UIViewController {
    var cubeLayer: CATransformLayer?
    var pinchGestureRecognizer: UIPinchGestureRecognizer?
    var panGestureRecognizer: UIPanGestureRecognizer?
    var panStartPoint: CGPoint = .zero
    var initialTransform: CATransform3D = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupCubeLayer()
        setupGestureRecognizers()
    }
}

// MARK: - Gesture Recognizer Setup

private extension ViewController {
    func setupGestureRecognizers() {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer = panGR
        
        view.addGestureRecognizer(panGR)
        
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGestureRecognizer = pinchGR
        
        view.addGestureRecognizer(pinchGR)
    }
    
    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cubeLayer = cubeLayer else { return }
        switch gesture.state {
        case .began:
            panStartPoint = .zero
            initialTransform = cubeLayer.transform
        case .changed:
            let translation = gesture.translation(in: view)
            let rotationTransform = CATransform3DConcat(CATransform3DMakeRotation(-translation.y / 90, 1, 0, 0),
                                                        CATransform3DMakeRotation(translation.x / 90, 0, 1, 0))
            cubeLayer.transform = CATransform3DConcat(initialTransform, rotationTransform)
        case .cancelled, .ended, .failed, .possible, .recognized:
            return
        @unknown default:
            fatalError()
        }
    }
    
    @objc
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let cubeLayer = cubeLayer else { return }
        switch gesture.state {
        case .began:
            initialTransform = cubeLayer.transform
        case .changed:
            let scaleTransform = CATransform3DMakeScale(gesture.scale, gesture.scale, gesture.scale)
            cubeLayer.transform = CATransform3DConcat(initialTransform, scaleTransform)
        case .cancelled, .ended, .failed, .possible, .recognized:
            return
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - Cube Setup

private extension ViewController {
    func setupCubeLayer() {
        let cubeLayer = makeCubeLayer()
        self.cubeLayer = cubeLayer
        
        cubeLayer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        view.layer.addSublayer(cubeLayer)
    }

    func makeCubeLayer() -> CATransformLayer {
        let faceLayers =
            CubeFace.allCases.map { face in
                faceLayer(for: face)
            }

        let cubeLayer = CATransformLayer()
    
        faceLayers.forEach { layer in
            cubeLayer.addSublayer(layer)
        }
        
        return cubeLayer
    }

    func faceLayer(for face: CubeFace) -> CALayer {
        let layer = VerticallyCenteringTextLayer()

        layer.string = face.text
        layer.alignmentMode = .center
        layer.fontSize = 72
        layer.foregroundColor = UIColor.black.cgColor
        layer.backgroundColor = face.color.cgColor
        layer.frame = CGRect(origin: CGPoint(x: -face.size.width/2, y: -face.size.height/2), size: face.size)
        layer.transform = faceTransform(for: face)

        return layer
    }
    
    func faceTransform(for face: CubeFace) -> CATransform3D {
        let translation = face.edgeLength / 2
        var transform: CATransform3D
        
        switch face {
        case .front:
            transform = CATransform3DMakeTranslation(0, 0, translation)
        case .back:
            transform = CATransform3DMakeTranslation(0, 0, -translation)
            transform = CATransform3DRotate(transform, CGFloat.pi, 0, 1, 0)
        case .left:
            transform = CATransform3DMakeTranslation(-translation, 0, 0)
            transform = CATransform3DRotate(transform, -CGFloat.pi / 2, 0, 1, 0)
        case .right:
            transform = CATransform3DMakeTranslation(translation, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat.pi / 2, 0, 1, 0)
        case .top:
            transform = CATransform3DMakeTranslation(0, -translation, 0)
            transform = CATransform3DRotate(transform, CGFloat.pi / 2, 1, 0, 0)
        case .bottom:
            transform = CATransform3DMakeTranslation(0, translation, 0)
            transform = CATransform3DRotate(transform, -CGFloat.pi / 2, 1, 0, 0)
        }
        
        return transform
    }
}

// MARK: - Helper Classes

/// CATextLayer doesn't support vertical centering and there's no property that allows you to change that.  This class vertically centers its text.
private class VerticallyCenteringTextLayer: CATextLayer {
    override open func draw(in ctx: CGContext) {
        let height = self.bounds.height
        let yDiff = (height-fontSize)/2 - fontSize/10
    
        ctx.saveGState()
        ctx.translateBy(x: 0.0, y: yDiff)
        
        super.draw(in: ctx)
        
        ctx.restoreGState()
    }
}
