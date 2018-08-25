//
//  VideoHelper.swift
//  ARKitImageRecognition
//
//  Created by Federico Nieto on 25/08/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit
import ARKit

struct videos {
    static let museoMarAficheAlpha = "MuseoMarAnimacionAlpha"
    static let musoMarAfiche = "MuseoMarAnimacion"
    static let manoOjo = "MANO_OJO"
    static let fire = "Fire"
    static let plane = "Plane"
}

struct videoExtension {
    static let mov = "mov"
    static let mp4 = "mp4"
}

class VideoHelper: NSObject {
    
    static func displayVideo(referenceImage: ARReferenceImage, node: SCNNode, video: String) {
        //2. Get The Physical Width & Height Of Our Reference Image
        let width = CGFloat(referenceImage.physicalSize.width)
        let height = CGFloat(referenceImage.physicalSize.height)
        
        //3. Create An SCNNode To Hold Our Video Player With The Same Size As The Image Target
        let videoHolder = SCNNode()
        let videoHolderGeometry = SCNPlane(width: width, height: height)
        videoHolder.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        videoHolder.geometry = videoHolderGeometry
        
        //4. Create Our Video Player
        if let videoURL = Bundle.main.url(forResource: videos.museoMarAficheAlpha,
                                          withExtension: videoExtension.mov) {
            setupVideoOnNode(videoHolder, fromURL: videoURL)
        }
        
        //5. Add It To The Hierarchy
        node.addChildNode(videoHolder)
    }
    
    /// Creates A Video Player As An SCNGeometries Diffuse Contents
    static func setupVideoOnNode(_ node: SCNNode, fromURL url: URL){
        
        //1. Create An SKVideoNode
        var videoPlayerNode: SKVideoNode!
        
        //2. Create An AVPlayer With Our Video URL
        let videoPlayer = AVPlayer(url: url)
        
        //3. Intialize The Video Node With Our Video Player
        videoPlayerNode = SKVideoNode(avPlayer: videoPlayer)
        videoPlayerNode.yScale = -1
        
        //4. Create A SpriteKitScene & Postion It
        let spriteKitScene = SKScene(size: CGSize(width: 1024, height: 768))
        spriteKitScene.scaleMode = .aspectFit
        videoPlayerNode.position = CGPoint(x: spriteKitScene.size.width/2, y: spriteKitScene.size.height/2)
        videoPlayerNode.size = spriteKitScene.size
        spriteKitScene.backgroundColor = .clear
        
        //5. Alpha transparency
        let effectNode = getAlphaEffectNode(videoPlayerNode: videoPlayerNode)
        spriteKitScene.addChild(effectNode)
        effectNode.addChild(videoPlayerNode)
        
        //6. Set The Nodes Geoemtry Diffuse Contenets To Our SpriteKit Scene
        node.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
        
        //7. Play The Video
        videoPlayerNode.play()
        videoPlayer.volume = 0
        
        //8. Loop Video
        loopVideo(videoPlayer: videoPlayer, node: node)
    }
    
    // MARK: - Transparency
    
    static func getAlphaEffectNode(videoPlayerNode: SKVideoNode) -> SKEffectNode {
        // Let's make it transparent, using an SKEffectNode,
        // since a shader cannot be applied to a SKVideoNode directly
        let effectNode = SKEffectNode()
        effectNode.shader = EffectNodeHelper.getAlphaShader()
        return effectNode
    }
    
    // MARK: - Loop
    static func loopVideo(videoPlayer: AVPlayer, node: SCNNode) {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: videoPlayer.currentItem,
                                               queue: nil) { (_) in
            videoPlayer.seek(to: kCMTimeZero)
            videoPlayer.play()
        }
    }
    
    // MARK: - Old Methods
    
    //    func applyAlphaChromaKey(forNode node: SCNNode) {
    //        let surfaceShader =
    //        """
    //uniform vec3 c_colorToReplace = vec3(0, 0, 0);
    //uniform float c_thresholdSensitivity = 0.05;
    //uniform float c_smoothing = 0.0;
    //
    //#pragma transparent
    //#pragma body
    //
    //vec3 textureColor = _surface.diffuse.rgb;
    //
    //float maskY = 0.2989 * c_colorToReplace.r + 0.5866 * c_colorToReplace.g + 0.1145 * c_colorToReplace.b;
    //float maskCr = 0.7132 * (c_colorToReplace.r - maskY);
    //float maskCb = 0.5647 * (c_colorToReplace.b - maskY);
    //
    //float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
    //float Cr = 0.7132 * (textureColor.r - Y);
    //float Cb = 0.5647 * (textureColor.b - Y);
    //
    //float blendValue = smoothstep(c_thresholdSensitivity, c_thresholdSensitivity + c_smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
    //
    //float a = blendValue;
    //_surface.transparent.a = a;
    //"""
    //        node.geometry?.shaderModifiers = [ .surface: surfaceShader ]
    //    }
    
    //    func displayVideo(referenceImage: ARReferenceImage, node: SCNNode) {
    //
    //        guard let currentFrame = self.sceneView.session.currentFrame else {
    //            return
    //        }
    //
    //        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
    //        let sceneView = SCNView(frame: bounds, options: [:])
    //        sceneView.backgroundColor = .black
    //        sceneView.allowsCameraControl = true
    //
    //        // Create scene
    //        let scene = SCNScene()
    //        // Create a plane to visualize the initial position of the detected image.
    //        let plane = SCNPlane(width: referenceImage.physicalSize.width,
    //                             height: referenceImage.physicalSize.height)
    //
    //        //Rotate video upside down
    //        let videoNode = SCNNode(geometry: plane)
    //        videoNode.eulerAngles.x = -.pi / 2
    //        videoNode.eulerAngles.y = .pi
    //
    //        node.addChildNode(videoNode)
    //
    //        let scene2d = MyVideoScene(size: bounds.size)
    //        scene2d.backgroundColor = .clear
    //        plane.firstMaterial?.diffuse.contents = scene2d
    //
    //        //self.sceneView.scene.rootNode.addChildNode(videoNode)
    //    }

}
