/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

struct referenceImages {
    static let handEye = "HandEye"
    static let aficheMuseoMar = "AficheMuseoMar"
    static let homeroMaddona = "HomeroMaddona"
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private struct Constants {
        static let ARResources = "AR Resources"
    }
    
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
        
        // Setup sceneView
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
        
        // Pause the session
        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        // Obtain images to recognize
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: Constants.ARResources,
                                                                     bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Setup ARSession configuration
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        //configuration.detectionImages = referenceImages
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Remove all nodes from the scene
        removeAllNodes()
        
        // Show look around to detect images message
        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
        
	}
    
    // MARK: - Remove all nodes from ARSCNView

    func removeAllNodes() {
        // Remove all nodes from the scene
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }

    // MARK: - ARSCNViewDelegate (Image detection results)
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            let referenceImage = imageAnchor.referenceImage
            
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
            planeNode.runAction(self.imageHighlightAction, completionHandler: {
                if referenceImage.name == referenceImages.aficheMuseoMar {
                    VideoHelper.displayVideo(referenceImage: referenceImage,
                                             node: node,
                                             video: Videos.museoMarAficheAlpha,
                                             videoExtension: VideoExtension.mov)
                }
            })
            
            // Add the plane visualization to the scene.
            node.addChildNode(planeNode)
            
            // Detected Image Message
            showDetectedImageMessage(referenceImage: referenceImage)
        }
    }
    
    // MARK : - Detected Image Message
    
    func showDetectedImageMessage(referenceImage: ARReferenceImage) {
        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }
    
    // MARK: - Image Highlight

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
}
