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
    
    static func displayVideo(referenceImage: ARReferenceImage,
                             node: SCNNode,
                             video: String,
                             videoExtension: String) {
        
        //1. Get The Physical Width & Height Of Our Reference Image
        let width = CGFloat(referenceImage.physicalSize.width)
        let height = CGFloat(referenceImage.physicalSize.height)

        //2. Create An SCNNode To Hold Our Video Player With The Same Size As The Image Target
        let videoHolder = SCNNode()
        let videoHolderGeometry = SCNPlane(width: width, height: height)
        videoHolder.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        videoHolder.geometry = videoHolderGeometry

        //3. Create Our Video Player
        if let videoURL = Bundle.main.url(forResource: video,
                                          withExtension: videoExtension) {
            setupVideoOnNode(videoHolder, fromURL: videoURL)
        }

        //4. Add It To The Hierarchy
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
    
    // MARK: - Loop Video
    
    static func loopVideo(videoPlayer: AVPlayer, node: SCNNode) {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: videoPlayer.currentItem,
                                               queue: nil) { (_) in
            videoPlayer.seek(to: kCMTimeZero)
            videoPlayer.play()
        }
    }

}
