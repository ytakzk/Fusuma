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
    
    var images: PHFetchResult!
    var imageManager: PHCachingImageManager?
    var previousPreheatRect: CGRect = CGRectZero
    let cellSize = CGSize(width: 100, height: 100)
    var phAsset: PHAsset!
    
    // Variables for calculating the position
    enum Direction {
        case Scroll
        case Stop
        case Up
        case Down
    }
    let imageCropViewOriginalConstraintTop: CGFloat = 50
    let imageCropViewMinimalVisibleHeight: CGFloat  = 100
    var dragDirection = Direction.Up
    var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    
    var cropBottomY: CGFloat  = 0.0
    var dragStartPos: CGPoint = CGPointZero
    let dragDiff: CGFloat     = 20.0
    
    static func instance() -> FSAlbumView {
        
        return UINib(nibName: "FSAlbumView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! FSAlbumView
    }
    
    func initialize() {
        
        if images != nil {
            
            return
        }
		
		self.hidden = false
        
        let panGesture      = UIPanGestureRecognizer(target: self, action: #selector(FSAlbumView.panned(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        collectionViewConstraintHeight.constant = self.frame.height - imageCropView.frame.height - imageCropViewOriginalConstraintTop
        imageCropViewConstraintTop.constant = 50
        dragDirection = Direction.Up
        
        imageCropViewContainer.layer.shadowColor   = UIColor.blackColor().CGColor
        imageCropViewContainer.layer.shadowRadius  = 30.0
        imageCropViewContainer.layer.shadowOpacity = 0.9
        imageCropViewContainer.layer.shadowOffset  = CGSizeZero
        
        collectionView.registerNib(UINib(nibName: "FSAlbumViewCell", bundle: NSBundle(forClass: self.classForCoder)), forCellWithReuseIdentifier: "FSAlbumViewCell")
		collectionView.backgroundColor = fusumaBackgroundColor
		
        // Never load photos Unless the user allows to access to photo album
        checkPhotoAuth()
        
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        images = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        
        if images.count > 0 {
            
            changeImage(images[0] as! PHAsset)
            collectionView.reloadData()
            collectionView.selectItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: UICollectionViewScrollPosition.None)
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
    }
    
    deinit {
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            
            PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func panned(sender: UITapGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            
            let view    = sender.view
            let loc     = sender.locationInView(view)
            let subview = view?.hitTest(loc, withEvent: nil)
            
            if subview == imageCropView && imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop {
                
                return
            }
            
            dragStartPos = sender.locationInView(self)
            
            cropBottomY = self.imageCropViewContainer.frame.origin.y + self.imageCropViewContainer.frame.height
            
            // Move
            if dragDirection == Direction.Stop {
                
                dragDirection = (imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop) ? Direction.Up : Direction.Down
            }
            
            // Scroll event of CollectionView is preferred.
            if (dragDirection == Direction.Up   && dragStartPos.y < cropBottomY + dragDiff) ||
                (dragDirection == Direction.Down && dragStartPos.y > cropBottomY) {
                    
                    dragDirection = Direction.Stop
                    
                    imageCropView.changeScrollable(false)
                    
            } else {
                
                imageCropView.changeScrollable(true)
            }
            
        } else if sender.state == UIGestureRecognizerState.Changed {
            
            let currentPos = sender.locationInView(self)
            
            if dragDirection == Direction.Up && currentPos.y < cropBottomY - dragDiff {
                
                imageCropViewConstraintTop.constant = max(imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height, currentPos.y + dragDiff - imageCropViewContainer.frame.height)
                
                collectionViewConstraintHeight.constant = min(self.frame.height - imageCropViewMinimalVisibleHeight, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            } else if dragDirection == Direction.Down && currentPos.y > cropBottomY {
                
                imageCropViewConstraintTop.constant = min(imageCropViewOriginalConstraintTop, currentPos.y - imageCropViewContainer.frame.height)
                
                collectionViewConstraintHeight.constant = max(self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            } else if dragDirection == Direction.Stop && collectionView.contentOffset.y < 0 {
                
                dragDirection = Direction.Scroll
                imaginaryCollectionViewOffsetStartPosY = currentPos.y
                
            } else if dragDirection == Direction.Scroll {
                
                imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height + currentPos.y - imaginaryCollectionViewOffsetStartPosY
                
                collectionViewConstraintHeight.constant = max(self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height, self.frame.height - imageCropViewConstraintTop.constant - imageCropViewContainer.frame.height)
                
            }
            
        } else {
            
            imaginaryCollectionViewOffsetStartPosY = 0.0
            
            if sender.state == UIGestureRecognizerState.Ended && dragDirection == Direction.Stop {
                
                imageCropView.changeScrollable(true)
                return
            }
            
            let currentPos = sender.locationInView(self)
            
            if currentPos.y < cropBottomY - dragDiff && imageCropViewConstraintTop.constant != imageCropViewOriginalConstraintTop {
                
                // The largest movement
                imageCropView.changeScrollable(false)
                
                imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.height
                
                collectionViewConstraintHeight.constant = self.frame.height - imageCropViewMinimalVisibleHeight
                
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    
                    self.layoutIfNeeded()
                    
                    }, completion: nil)
                
                dragDirection = Direction.Down
                
            } else {
                
                // Get back to the original position
                imageCropView.changeScrollable(true)
                
                imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
                collectionViewConstraintHeight.constant = self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height
                
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    
                    self.layoutIfNeeded()
                    
                    }, completion: nil)
                
                dragDirection = Direction.Up
                
            }
        }
        
        
    }
    
    
    // MARK: - UICollectionViewDelegate Protocol
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FSAlbumViewCell", forIndexPath: indexPath) as! FSAlbumViewCell
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        let asset = self.images[indexPath.item] as! PHAsset
        self.imageManager?.requestImageForAsset(asset,
            targetSize: cellSize,
            contentMode: .AspectFill,
            options: nil) {
                result, info in
                
                if cell.tag == currentTag {
                    cell.image = result
                }
                
        }
        
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images == nil ? 0 : images.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        changeImage(images[indexPath.row] as! PHAsset)
        
        imageCropView.changeScrollable(true)
        
        imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
        collectionViewConstraintHeight.constant = self.frame.height - imageCropViewOriginalConstraintTop - imageCropViewContainer.frame.height
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.layoutIfNeeded()
            
            }, completion: nil)
        
        dragDirection = Direction.Up
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
    }
    
    
    // MARK: - ScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if scrollView == collectionView {
            self.updateCachedAssets()
        }
    }
    
    
    //MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            let collectionChanges = changeInstance.changeDetailsForFetchResult(self.images)
            if collectionChanges != nil {
                
                self.images = collectionChanges!.fetchResultAfterChanges
                
                let collectionView = self.collectionView!
                
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    
                    collectionView.reloadData()
                    
                } else {
                    
                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItemsAtIndexPaths(removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItemsAtIndexPaths(insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let changedIndexes = collectionChanges!.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 {
                            collectionView.reloadItemsAtIndexPaths(changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        }, completion: nil)
                }
                
                self.resetCachedAssets()
            }
        }
    }
}

internal extension UICollectionView {
    
    func aapl_indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        var indexPaths: [NSIndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
}

internal extension NSIndexSet {
    
    func aapl_indexPathsFromIndexesWithSection(section: Int) -> [NSIndexPath] {
        var indexPaths: [NSIndexPath] = []
        indexPaths.reserveCapacity(self.count)
        self.enumerateIndexesUsingBlock {idx, stop in
            indexPaths.append(NSIndexPath(forItem: idx, inSection: section))
        }
        return indexPaths
    }
}

private extension FSAlbumView {
    
    func changeImage(asset: PHAsset) {
        
        self.imageCropView.image = nil
        self.phAsset = asset
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let options = PHImageRequestOptions()
            options.networkAccessAllowed = true
            
            self.imageManager?.requestImageForAsset(asset,
                targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                contentMode: .AspectFill,
                options: options) {
                    result, info in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.imageCropView.imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                        self.imageCropView.image = result
                    })
            }
        })
    }
    
    // Check the status of authorization for PHPhotoLibrary
    private func checkPhotoAuth() {
        
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .Authorized:
                self.imageManager = PHCachingImageManager()
                if self.images != nil && self.images.count > 0 {
                    
                    self.changeImage(self.images[0] as! PHAsset)
                }
                
            case .Restricted, .Denied:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
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
        previousPreheatRect = CGRectZero
    }
 
    func updateCachedAssets() {
        
        var preheatRect = self.collectionView!.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))
        
        let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect))
        if delta > CGRectGetHeight(self.collectionView!.bounds) / 3.0 {
            
            var addedIndexPaths: [NSIndexPath] = []
            var removedIndexPaths: [NSIndexPath] = []
            
            self.computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect, removedHandler: {removedRect in
                let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
                }, addedHandler: {addedRect in
                    let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                    addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)
            
            self.imageManager?.startCachingImagesForAssets(assetsToStartCaching,
                targetSize: cellSize,
                contentMode: .AspectFill,
                options: nil)
            self.imageManager?.stopCachingImagesForAssets(assetsToStopCaching,
                targetSize: cellSize,
                contentMode: .AspectFill,
                options: nil)
            
            self.previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(oldRect: CGRect, andRect newRect: CGRect, removedHandler: CGRect->Void, addedHandler: CGRect->Void) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            if newMaxY > oldMaxY {
                let rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        
        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
            let asset = self.images[indexPath.item] as! PHAsset
            assets.append(asset)
        }
        return assets
    }
}