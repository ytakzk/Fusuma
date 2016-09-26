//
//  FSAlbumView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos

@objc public protocol FSAlbumViewDelegate: class {
    
    func albumViewCameraRollUnauthorized()
}

final class FSAlbumView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageCropView: FSImageCropView!
    @IBOutlet weak var imageCropViewContainer: UIView!
    
    @IBOutlet weak var collectionViewConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var imageCropViewConstraintTop: NSLayoutConstraint!
    
    weak var delegate: FSAlbumViewDelegate? = nil
    
    var images: PHFetchResult<PHAsset>!
    var imageManager: PHCachingImageManager?
    var previousPreheatRect: CGRect = CGRect.zero
    let cellSize = CGSize(width: 100, height: 100)
    var phAsset: PHAsset!
    
    // Variables for calculating the position
    enum Direction {
        case scroll
        case stop
        case up
        case down
    }
    let imageCropViewOriginalConstraintTop: CGFloat = 50
    let imageCropViewMinimalVisibleHeight: CGFloat  = 100
    var dragDirection = Direction.up
    var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    
    var cropBottomY: CGFloat  = 0.0
    var dragStartPos: CGPoint = CGPoint.zero
    let dragDiff: CGFloat     = 20.0
    
    static func instance() -> FSAlbumView {
        
        return UINib(nibName: "FSAlbumView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSAlbumView
    }
    
    func initialize() {
        
        if images != nil {
            
            return
        }
		
		self.isHidden = false
        
        let panGesture      = UIPanGestureRecognizer(target: self, action: #selector(FSAlbumView.panned(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        collectionViewConstraintHeight.constant = self.frame.height - imageCropView.frame.height - imageCropViewOriginalConstraintTop
        imageCropViewConstraintTop.constant = 50
        dragDirection = Direction.up
        
        imageCropViewContainer.layer.shadowColor   = UIColor.black.cgColor
        imageCropViewContainer.layer.shadowRadius  = 30.0
        imageCropViewContainer.layer.shadowOpacity = 0.9
        imageCropViewContainer.layer.shadowOffset  = CGSize.zero
        
        collectionView.register(UINib(nibName: "FSAlbumViewCell", bundle: Bundle(for: self.classForCoder)), forCellWithReuseIdentifier: "FSAlbumViewCell")
		collectionView.backgroundColor = fusumaBackgroundColor
		
        // Never load photos Unless the user allows to access to photo album
        checkPhotoAuth()
        
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        images = PHAsset.fetchAssets(with: .image, options: options)
        
        if images.count > 0 {
            
            changeImage(images[0])
            collectionView.reloadData()
            collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: UICollectionViewScrollPosition())
        }
        
        PHPhotoLibrary.shared().register(self)
        
    }
    
    deinit {
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func panned(_ sender: UITapGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.began {
            
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)
            
            if subview == imageCropView && imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop {
                
                return
            }
            
            dragStartPos = sender.location(in: self)
            
            cropBottomY = self.imageCropViewContainer.frame.origin.y + self.imageCropViewContainer.frame.height
            
            // Move
            if dragDirection == Direction.stop {
                
                dragDirection = (imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop) ? Direction.up : Direction.down
            }
            
            // Scroll event of CollectionView is preferred.
            if (dragDirection == Direction.up   && dragStartPos.y < cropBottomY + dragDiff) ||
                (dragDirection == Direction.down && dragStartPos.y > cropBottomY) {
                    
                    dragDirection = Direction.stop
                    
                    imageCropView.changeScrollable(false)
                    
            } else {
                
                imageCropView.changeScrollable(true)
            }
            
        } else if sender.state == UIGestureRecognizerState.changed {
            
            let currentPos = sender.location(in: self)
            
            if dragDirection == Direction.up && currentPos.y < cropBottomY - dragDiff {
                
                imageCropViewConstraintTop.constant = max(imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height, currentPos.y + dragDiff - imageCropViewContainer.frame.height)
                
                collectionViewConstraintHeight.constant = min(self.frame.height - imageCropViewMinimalVisibleHeight, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            } else if dragDirection == Direction.down && currentPos.y > cropBottomY {
                
                imageCropViewConstraintTop.constant = min(imageCropViewOriginalConstraintTop, currentPos.y - imageCropViewContainer.frame.height)
                
                collectionViewConstraintHeight.constant = max(self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            } else if dragDirection == Direction.stop && collectionView.contentOffset.y < 0 {
                
                dragDirection = Direction.scroll
                imaginaryCollectionViewOffsetStartPosY = currentPos.y
                
            } else if dragDirection == Direction.scroll {
                
                imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height + currentPos.y - imaginaryCollectionViewOffsetStartPosY
                
                collectionViewConstraintHeight.constant = max(self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            }
            
        } else {
            
            imaginaryCollectionViewOffsetStartPosY = 0.0
            
            if sender.state == UIGestureRecognizerState.ended && dragDirection == Direction.stop {
                
                imageCropView.changeScrollable(true)
                return
            }
            
            let currentPos = sender.location(in: self)
            
            if currentPos.y < cropBottomY - dragDiff && imageCropViewConstraintTop.constant != imageCropViewOriginalConstraintTop {
                
                // The largest movement
                imageCropView.changeScrollable(false)
                
                imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height
                
                collectionViewConstraintHeight.constant = self.frame.height - imageCropViewMinimalVisibleHeight
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    
                    self.layoutIfNeeded()
                    
                    }, completion: nil)
                
                dragDirection = Direction.down
                
            } else {
                
                // Get back to the original position
                imageCropView.changeScrollable(true)
                
                imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
                collectionViewConstraintHeight.constant = self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    
                    self.layoutIfNeeded()
                    
                    }, completion: nil)
                
                dragDirection = Direction.up
                
            }
        }
        
        
    }
    
    
    // MARK: - UICollectionViewDelegate Protocol
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FSAlbumViewCell", for: indexPath) as! FSAlbumViewCell
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        let asset = self.images[(indexPath as NSIndexPath).item]
        self.imageManager?.requestImage(for: asset,
            targetSize: cellSize,
            contentMode: .aspectFill,
            options: nil) {
                result, info in
                
                if cell.tag == currentTag {
                    cell.image = result
                }
                
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images == nil ? 0 : images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        changeImage(images[(indexPath as NSIndexPath).row])
        
        imageCropView.changeScrollable(true)
        
        imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
        collectionViewConstraintHeight.constant = self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            
            self.layoutIfNeeded()
            
            }, completion: nil)
        
        dragDirection = Direction.up
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }
    
    
    // MARK: - ScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == collectionView {
            self.updateCachedAssets()
        }
    }
    
    
    //MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.async {
            
            let collectionChanges = changeInstance.changeDetails(for: self.images)
            if collectionChanges != nil {
                
                self.images = collectionChanges!.fetchResultAfterChanges
                
                let collectionView = self.collectionView!
                
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    
                    collectionView.reloadData()
                    
                } else {
                    
                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItems(at: removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItems(at: insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let changedIndexes = collectionChanges!.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 {
                            collectionView.reloadItems(at: changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        }, completion: nil)
                }
                
                self.resetCachedAssets()
            }
        }
    }
}

internal extension UICollectionView {
    
    func aapl_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
}

internal extension IndexSet {
    
    func aapl_indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(self.count)
        (self as NSIndexSet).enumerate({idx, stop in
            indexPaths.append(IndexPath(item: idx, section: section))
        })
        return indexPaths
    }
}

private extension FSAlbumView {
    
    func changeImage(_ asset: PHAsset) {
        
        self.imageCropView.image = nil
        self.phAsset = asset
        
        DispatchQueue.global(qos: .default).async(execute: {
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            
            self.imageManager?.requestImage(for: asset,
                targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                contentMode: .aspectFill,
                options: options) {
                    result, info in
                    
                    DispatchQueue.main.async(execute: {
                        
                        self.imageCropView.imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                        self.imageCropView.image = result
                    })
            }
        })
    }
    
    // Check the status of authorization for PHPhotoLibrary
    func checkPhotoAuth() {
        
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .authorized:
                self.imageManager = PHCachingImageManager()
                if self.images != nil && self.images.count > 0 {
                    
                    self.changeImage(self.images[0])
                }
                
            case .restricted, .denied:
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.delegate?.albumViewCameraRollUnauthorized()
                    
                })
            default:
                break
            }
        }
    }

    // MARK: - Asset Caching
    
    func resetCachedAssets() {
        
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero
    }
 
    func updateCachedAssets() {
        
        var preheatRect = self.collectionView!.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - self.previousPreheatRect.midY)
        if delta > self.collectionView!.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            self.computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect, removedHandler: {removedRect in
                let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
                }, addedHandler: {addedRect in
                    let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                    addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)
            
            self.imageManager?.startCachingImages(for: assetsToStartCaching,
                targetSize: cellSize,
                contentMode: .aspectFill,
                options: nil)
            self.imageManager?.stopCachingImages(for: assetsToStopCaching,
                targetSize: cellSize,
                contentMode: .aspectFill,
                options: nil)
            
            self.previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect, andRect newRect: CGRect, removedHandler: (CGRect)->Void, addedHandler: (CGRect)->Void) {
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        
        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
            let asset = self.images[(indexPath as NSIndexPath).item]
            assets.append(asset)
        }
        return assets
    }
}
