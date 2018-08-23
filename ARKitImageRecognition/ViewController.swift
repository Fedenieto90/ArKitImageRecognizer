/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import Lottie

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            
            // Create a plane to visualize the initial position of the detected image.
            let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.25
            
            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2
            
            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
            planeNode.runAction(self.imageHighlightAction)
            
            // Add the plane visualization to the scene.
            //node.addChildNode(planeNode)
            
            // Display Video
            if referenceImage.name == "HandEye" {
                //self.displayVideo(referenceImage: referenceImage, node: node)
                self.displayLottieAnimation(referenceImage: referenceImage,
                                            node: node)
            } else if referenceImage.name == "AficheMuseoMar" {
                self.displayVideoOverRecognizedImage(referenceImage: referenceImage,
                                                     node: node)
            }

        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("Updated")
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
    
    func displayVideo(referenceImage: ARReferenceImage, node: SCNNode) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        let sceneView = SCNView(frame: bounds, options: [:])
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = true
        
        // Create scene
        let scene = SCNScene()
        // Create a plane to visualize the initial position of the detected image.
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height)
        
        //Rotate video upside down
        let videoNode = SCNNode(geometry: plane)
        videoNode.eulerAngles.x = -.pi / 2
        videoNode.eulerAngles.y = .pi
        
        node.addChildNode(videoNode)
        
        let scene2d = MyVideoScene(size: bounds.size)
        scene2d.backgroundColor = .clear
        plane.firstMaterial?.diffuse.contents = scene2d
        
        //self.sceneView.scene.rootNode.addChildNode(videoNode)
    }
    
    func displayLottieAnimation(referenceImage: ARReferenceImage, node: SCNNode) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        // create lottie view
        DispatchQueue.main.async {
            let animationView = LOTAnimationView(name: "love_explosion")
            animationView.loopAnimation = true
            animationView.play()
            // Create a plane to visualize the initial position of the detected image.
            let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = animationView
            let animationNode = SCNNode(geometry: plane)
            animationNode.eulerAngles.x = -.pi / 2
            node.addChildNode(animationNode)
        }
    
    }
    
    func displayVideoOverRecognizedImage(referenceImage: ARReferenceImage, node: SCNNode) {
        //2. Get The Physical Width & Height Of Our Reference Image
        let width = CGFloat(referenceImage.physicalSize.width)
        let height = CGFloat(referenceImage.physicalSize.height)
        
        //3. Create An SCNNode To Hold Our Video Player With The Same Size As The Image Target
        let videoHolder = SCNNode()
        let videoHolderGeometry = SCNPlane(width: width, height: height)
        videoHolder.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        videoHolder.geometry = videoHolderGeometry
        
        //4. Create Our Video Player
        if let videoURL = Bundle.main.url(forResource: "Fire", withExtension: "mp4"){
            setupVideoOnNode(videoHolder, fromURL: videoURL)
        }
        
        //5. Add It To The Hierarchy
        node.addChildNode(videoHolder)
    }
    
    /// Creates A Video Player As An SCNGeometries Diffuse Contents
    func setupVideoOnNode(_ node: SCNNode, fromURL url: URL){
        
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
        //spriteKitScene.addChild(videoPlayerNode)
        spriteKitScene.backgroundColor = .clear
        
        //Chroma key for transparent background
        //applyAlphaChromaKey(forNode: node)
        
        // Let's make it transparent, using an SKEffectNode,
        // since a shader cannot be applied to a SKVideoNode directly
        let effectNode = SKEffectNode()
        // Loving Swift's multiline syntax here:
        effectNode.shader = SKShader(source: """
void main() {
  vec2 texCoords = v_tex_coord;
  vec2 colorCoords = vec2(texCoords.x, texCoords.y);
  vec2 alphaCoords = vec2(texCoords.x, texCoords.y);
  vec4 color = texture2D(u_texture, colorCoords);
  float alpha = texture2D(u_texture, alphaCoords).r;
  gl_FragColor = vec4(color.rgb, alpha);
}
""")
        spriteKitScene.addChild(effectNode)
        effectNode.addChild(videoPlayerNode)
        
        //6. Set The Nodes Geoemtry Diffuse Contenets To Our SpriteKit Scene
        node.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
        
        //5. Play The Video
        videoPlayerNode.play()
        videoPlayer.volume = 0
    }
    
    func applyAlphaChromaKey(forNode node: SCNNode) {
        let surfaceShader =
        """
uniform vec3 c_colorToReplace = vec3(0, 0, 0);
uniform float c_thresholdSensitivity = 0.05;
uniform float c_smoothing = 0.0;

#pragma transparent
#pragma body

vec3 textureColor = _surface.diffuse.rgb;

float maskY = 0.2989 * c_colorToReplace.r + 0.5866 * c_colorToReplace.g + 0.1145 * c_colorToReplace.b;
float maskCr = 0.7132 * (c_colorToReplace.r - maskY);
float maskCb = 0.5647 * (c_colorToReplace.b - maskY);

float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
float Cr = 0.7132 * (textureColor.r - Y);
float Cb = 0.5647 * (textureColor.b - Y);

float blendValue = smoothstep(c_thresholdSensitivity, c_thresholdSensitivity + c_smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));

float a = blendValue;
_surface.transparent.a = a;
"""
        node.geometry?.shaderModifiers = [ .surface: surfaceShader ]
    }
}
