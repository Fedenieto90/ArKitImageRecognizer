//
//  MyVideoScene.swift
//  ARKitImageRecognition
//
//  Created by Federico Nieto on 10/08/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import SceneKit
import SpriteKit

class MyVideoScene: SKScene {
    
    var player: AVPlayer!
    var playerLooper: AVPlayerLooper!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        //  override func didMove(to view: SKView) {
        
        guard let url = Bundle.main.url(forResource: "Fire", withExtension: "mp4") else {
            print("Can't find example video")
            return
        }
        
        // Creating our player
        let playerItem = AVPlayerItem(url: url)
        player = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: player as! AVQueuePlayer, templateItem: playerItem)
        
        // Getting the size of our video
        let videoTrack = playerItem.asset.tracks(withMediaType: .video).first!
        let videoSize = videoTrack.naturalSize
        
        // Adding a `SKVideoNode` to display video in our scene
        let videoNode = SKVideoNode(avPlayer: player)
        videoNode.position = CGPoint(x: frame.midX, y: frame.midY)
        videoNode.size = videoSize.applying(CGAffineTransform(scaleX: 1.0, y: 0.5))
        
        
        // Let's make it transparent, using an SKEffectNode,
        // since a shader cannot be applied to a SKVideoNode directly
        let effectNode = SKEffectNode()
        // Loving Swift's multiline syntax here:
        effectNode.shader = SKShader(source: """
void main() {
  vec2 texCoords = v_tex_coord;
  vec2 colorCoords = vec2(texCoords.x, (1.0 + texCoords.y) * 0.5);
  vec2 alphaCoords = vec2(texCoords.x, texCoords.y * 0.5);
  vec4 color = texture2D(u_texture, colorCoords);
  float alpha = texture2D(u_texture, alphaCoords).r;
  gl_FragColor = vec4(color.rgb, alpha);
}
""")
        addChild(effectNode)
        effectNode.addChild(videoNode)
        
        player.play()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
