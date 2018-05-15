
// Abstract: Methods on the main view controller for handling virtual object loading and movement

import UIKit
import ARKit

extension MainVC: VirtualObjectSelectionVCDelegate, SavesListVCDelegate {
     // Adds the specified virtual object to the scene, placed using the focus square's estimate of the world-space position currently corresponding to the center of the screen.
     // - Tag: PlaceVirtualObject
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform, let focusSquareAlignment = focusSquare.recentFocusSquareAlignments.last, focusSquare.state != .initializing else {
            statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.".localized(using: "MainStrings"))
            if let index = virtualObjectLoader.loadedObjects.index(of: virtualObject) {
                virtualObjectLoader.removeVirtualObject(at: index)
            }
            return
        }
		
		// The focus square transform may contain a scale component, so reset scale to 1
		let focusSquareScaleInverse = 1.0 / focusSquare.simdScale.x
        let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
		let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
		
        virtualObjectInteraction.selectedObject = virtualObject
		virtualObject.setTransform(focusSquareTransformWithoutScale, relativeTo: cameraTransform, smoothMovement: false, alignment: focusSquareAlignment, allowAnimation: false)
        
        updateQueue.async {
            // Substantial addition
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
			self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
        
        NotificationCenter.default.post(name: NOTIF_SET_INFO_RM_BUTTON, object: nil)
        NotificationCenter.default.post(name: NOTIF_SHOW_MESSAGE, object: virtualObjectInteraction.selectedObject?.getLocalizedName())
    }
    
    // MARK: - VirtualObjectSelectionVCDelegate
    // Select a object and place
    func virtualObjectSelectionVC(_: VirtualObjectSelectionVC, didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })
        displayObjectLoadingUI()
    }
    
    func savesListVC(_ listVC: SavesListVC, loadObjects: [VirtualObject], objectRotations: [Float]) {
        virtualObjectLoader.removeAllVirtualObjects()
        
        for index in 0..<loadObjects.count {
            virtualObjectLoader.loadVirtualObject(loadObjects[index]) { (loadedObject) in
                DispatchQueue.main.sync {
                    self.hideObjectLoadingUI()
                    // Not changed
                    print("pre position: \(loadedObject.position.x), \(loadedObject.position.y), \(loadedObject.position.z)")
                    let position = loadedObject.position
                    // The position changes to match FocusSquare.
                    self.placeVirtualObject(loadedObject)
                    // Changed
                    print("post position: \(loadedObject.position.x), \(loadedObject.position.y), \(loadedObject.position.z)")
                    loadedObject.position = position
                    loadedObject.objectRotation = objectRotations[index]
                }
            }
        }
    }
    
    func savesListVC(_ listVC: SavesListVC, getCurrentSession: Bool) -> ARSession {
        if getCurrentSession {
            return session
        } else {
            return ARSession()
        }
    }
    
    func savesListVC(_ listVC: SavesListVC, getLoadedVirtualObjects: Bool) -> [VirtualObject] {
        if getLoadedVirtualObjects {
            return virtualObjectLoader.loadedObjects
        } else {
            return [VirtualObject]()
        }
    }
    
    func savesListVC(_ listVC: SavesListVC, getVirtualObjects: Bool) -> [VirtualObject] {
        if getVirtualObjects {
            return virtualObjects
        } else {
            return [VirtualObject]()
        }
    }
    
    // MARK: Object Loading UI
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}