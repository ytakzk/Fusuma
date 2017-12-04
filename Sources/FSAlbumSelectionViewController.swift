//
//  FSAlbumSelectionViewController.swift
//  Burpple2
//
//  Created by John Kuan on 14/8/17.
//  Copyright © 2017 Burpple Pte Ltd. All rights reserved.
//

import UIKit
import Photos

typealias AssetCollectionTuple = (collection: PHAssetCollectionType, subType: PHAssetCollectionSubtype)

@objc enum AlbumCollectionType: Int {
    case cameraRoll
    case video
    case allUserAlbum
    case allUserSmartAlbum
    case favorites

    func getPHAssetCollectionType() -> AssetCollectionTuple {
        switch self {
        case .cameraRoll:
            return (PHAssetCollectionType.smartAlbum, PHAssetCollectionSubtype.smartAlbumUserLibrary)
        case .video:
            return (PHAssetCollectionType.smartAlbum, PHAssetCollectionSubtype.smartAlbumVideos)
        case .allUserAlbum:
            return (PHAssetCollectionType.album, PHAssetCollectionSubtype.any)
        case .allUserSmartAlbum:
            return (PHAssetCollectionType.smartAlbum, PHAssetCollectionSubtype.any)
        case .favorites:
            return (PHAssetCollectionType.smartAlbum, PHAssetCollectionSubtype.smartAlbumFavorites)
        }
    }
}

@objc enum FSAlbumAssetType: Int {
    case photos, videos, both
}

@objc class AlbumModel: NSObject {
    let collection: PHAssetCollection
    var asset: PHAsset
    var image: UIImage?
    init(collection: PHAssetCollection, asset: PHAsset) {
        self.collection = collection
        self.asset = asset
    }

    func updateImage(image: UIImage?) {
        self.image = image
    }
}

@objc protocol FSAlbumSelectionViewControllerDelegate: NSObjectProtocol {
    func didSelectAlbum(sender: FSAlbumSelectionViewController, albumSelected: AlbumModel)
    @objc optional func didSelectCancel(sender: FSAlbumSelectionViewController)
}

class FSAlbumSelectionViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FSAlbumSelectionTableViewCell.self, forCellReuseIdentifier: "albumlist")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        return tableView
    }()

    var album: [AlbumModel] = [AlbumModel]()
    fileprivate var imageManager: PHCachingImageManager?
    fileprivate var delegate: FSAlbumSelectionViewControllerDelegate?
    var albumTypeArray: [AlbumCollectionType] = [.cameraRoll, .favorites, .allUserAlbum]
    fileprivate lazy var assetFetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if #available(iOS 9.0, *) {
            fetchOptions.fetchLimit = 1
        }
        return fetchOptions
    }()
    
    public var assetType: FSAlbumAssetType = .both

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
        if let navController = navigationController {
            navController.navigationBar.barStyle = .default
            navController.navigationBar.isTranslucent = false
            navController.navigationBar.barTintColor = .white
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if album.isEmpty {
            listAlbums()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    init(delegate: FSAlbumSelectionViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        modalPresentationStyle = .overCurrentContext
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FSAlbumSelectionViewController {
    func prepareViews() {

        if #available(iOS 9.0, *) {
            if #available(iOS 11.0, *) {
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            } else {
                tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            }
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        } else {
            tableView.addConstraints([
                NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
                ])
        }
        
        imageManager = PHCachingImageManager()

        
        let cButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        cButton.setBackgroundImage(UIImage(named: "ic_close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        cButton.tintColor = fusumaTintColor
        cButton.addTarget(self, action: #selector(closeViewController), for: .touchUpInside)
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: cButton), animated: false)
        //        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeViewController))
//        let image = UIImage(named: "ic_close")?.withRenderingMode(.alwaysTemplate)
//        let closeButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(closeViewController))
//        navigationItem.setLeftBarButton(closeButton, animated: false)
        navigationItem.title = NSLocalizedString("Choose Album", comment: "Navigation title to choose album")
    }

    @objc func closeViewController() {
        delegate?.didSelectCancel?(sender: self)
    }
}

extension FSAlbumSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAlbum = album[indexPath.row]
        delegate?.didSelectAlbum(sender: self, albumSelected: selectedAlbum)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FSAlbumSelectionTableViewCell.rowHeight
    }
}

extension FSAlbumSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return album.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumlist", for: indexPath) as! FSAlbumSelectionTableViewCell
        let item = album[indexPath.row]

        if let previewImage = item.image {
            cell.setup(albumDetails: item, image: previewImage)
        } else {
            cell.setup(albumDetails: item, image: nil)

            let scale = UIScreen.main.scale
            let imageSize = CGSize(width: FSAlbumSelectionTableViewCell.imageSize * scale, height: FSAlbumSelectionTableViewCell.imageSize * scale)
            let options = PHImageRequestOptions()
            options.isSynchronous = true

            imageManager?.requestImage(for: item.asset,
                                       targetSize: imageSize,
                                       contentMode: .aspectFill,
                                       options: options) {
                result, info in
                DispatchQueue.main.async {
                    if let found = tableView.indexPathsForVisibleRows?.contains(indexPath), found == true {
                        cell.updateImage(image: result)
                    }
                    item.updateImage(image: result)
                }
            }
        }

        return cell
    }
}

extension FSAlbumSelectionViewController {
    // find all user created albums
    func listAlbums() {
        DispatchQueue.main.async {
            var album: [AlbumModel] = [AlbumModel]()
            var assetArray: [PHAsset] = [PHAsset]()

            let options = PHFetchOptions()
            if #available(iOS 9.0, *) {
                options.includeAssetSourceTypes = .typeUserLibrary
            } else {
                // Fallback on earlier versions
                
            }

            for item in self.albumTypeArray {
                let collectionTuple = item.getPHAssetCollectionType()
                let albumCollection = PHAssetCollection.fetchAssetCollections(with: collectionTuple.collection, subtype: collectionTuple.subType, options: options)
                albumCollection.enumerateObjects(_:) { object, count, stop in
                    let fetchResult = PHAsset.fetchAssets(in: object, options: self.assetFetchOptions)
                    guard let asset = fetchResult.firstObject else {
                        return
                    }

                    let newAlbum = AlbumModel(collection: object, asset: asset)
                    album.append(newAlbum)
                    assetArray.append(asset)
                }
            }

            self.album = album

            self.tableView.beginUpdates()
            let section = IndexSet(integer: 0)
            self.tableView.reloadSections(section, with: .fade)
            self.tableView.endUpdates()

            self.cacheAllFirstImages(assetArray: assetArray)
        }
    }

    func cacheAllFirstImages(assetArray: [PHAsset]) {
        let imageSize = CGSize(width: FSAlbumSelectionTableViewCell.imageSize, height: FSAlbumSelectionTableViewCell.imageSize)
        DispatchQueue.main.async(execute: {
            self.imageManager?.startCachingImages(for: assetArray, targetSize: imageSize, contentMode: .aspectFill, options: PHImageRequestOptions())
        })
    }

    func createAssetFetchOptions() -> PHFetchOptions? {
        let createImagePredicate = { () -> NSPredicate in
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        }

        let createVideoPredicate = { () -> NSPredicate in
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        }

        var predicate: NSPredicate?
        switch assetType {
        case .both:
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [createImagePredicate(), createVideoPredicate()])
        case .photos:
            predicate = createImagePredicate()
        case .videos:
            predicate = createVideoPredicate()
        }

        assetFetchOptions.predicate = predicate

        return assetFetchOptions
    }
}

extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        return result.count
    }
}
