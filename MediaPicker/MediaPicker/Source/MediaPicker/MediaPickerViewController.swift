//
// 
//  Workspace: MediaPicker
//  MacOS Version: 11.4
//			
//  File Name: MediaPickerViewController.swift
//  Creation: 6/4/21 3:27 PM
//
//  Author: Dragos-Costin Mandu
//
//


import UIKit
import PhotosUI
import os
import CoreHaptics
import ImagePlayer
import VidePlayer

public class MediaPickerViewController: UIViewController
{
    // MARK: - Initialization
    public static var s_LoggerSubsystem: String = Bundle.main.bundleIdentifier!
    public static var s_LoggerCategory: String = "MediaPickerViewController"
    public static var s_Logger: Logger = .init(subsystem: s_LoggerSubsystem, category: s_LoggerCategory)
    
    /// The number o images/videos/gifs in a single row of the library.
    public static var s_NumberOfMediaInRow: Int = 3
    public static var s_MinimumInteritemSpacing: CGFloat = 4
    public static var s_MediaCornerRadius: CGFloat = 16
    
    /// The ratio between the item size and the indicators for videos or GIFs padding (bottom, trailing).
    public static var s_VideoGifIndicatorPaddingRatio: CGFloat = 0.065
    
    /// The ratio between the item size and the indicators for videos or GIFs.
    public static var s_VideoGifIndicatorPointSizeRatio: CGFloat = 0.085
    
    private var m_CollectionView: UICollectionView!
    private var m_CollectionViewLayout: UICollectionViewFlowLayout!
    private var m_CellId: String = "PhotosLibraryCellId"
    private var m_FetchResult: PHFetchResult<PHAsset>!
    private var m_ImageManager: PHImageManager = .init()
    private var m_HighlightedMediaIndexPath: IndexPath? = nil
    private var m_SelectedAssetIndeces: [Int] = []
    private var m_ImageRequestOptions: PHImageRequestOptions
    {
        let options = PHImageRequestOptions()
        
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        return options
    }
    private var m_VideoRequestOptions: PHVideoRequestOptions
    {
        let options = PHVideoRequestOptions()
        
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        return options
    }
    private var m_ItemSize: CGSize
    {
        let length = (view.frame.size.width - 3 * MediaPickerViewController.s_MinimumInteritemSpacing) / CGFloat(MediaPickerViewController.s_NumberOfMediaInRow)
        
        return .init(width: length, height: length)
    }
    
    public var delegate: MediaPickerDelegate? = nil
    public var maxSelectedAssets: Int = 1
    
    public init()
    {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
}

public extension MediaPickerViewController
{
    // MARK: - Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        configure()
        fetchAssets()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        fetchAssets()
        m_CollectionView.collectionViewLayout.invalidateLayout()
        m_CollectionView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        m_CollectionView.reloadData()
    }
}

private extension MediaPickerViewController
{
    // MARK: - Updates
    
    func fetchAssets()
    {
        let options = PHFetchOptions()
        let creationDateDescriptorKey = "creationDate"
        
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        options.sortDescriptors =
            [
                NSSortDescriptor(key: creationDateDescriptorKey, ascending: false) // Ordered by date.
            ]
        
        m_FetchResult = PHAsset.fetchAssets(with: options) // Fetch all types.
    }
    
    /// When selected assets are deselected, the didDeselectAsset delegate is called for each one.
    func deselectAllSelectedAssets()
    {
        while true
        {
            let selectedAssetIndex = m_SelectedAssetIndeces.removeLast()
            delegate?.didDeselectAsset(self, assetIndex: selectedAssetIndex)
            if m_SelectedAssetIndeces.count == 0 { break }
        }
        
        m_CollectionView.reloadData()
    }
}

private extension MediaPickerViewController
{
    // MARK: - Configuration
    
    func configure()
    {
        configuresCollectionViewLayout()
        configureCollectionView()
        setAppStateObservers()
    }
    
    func configuresCollectionViewLayout()
    {
        m_CollectionViewLayout = .init()
        
        m_CollectionViewLayout.minimumInteritemSpacing = MediaPickerViewController.s_MinimumInteritemSpacing
        m_CollectionViewLayout.minimumLineSpacing = 0
        m_CollectionViewLayout.estimatedItemSize = .zero
        m_CollectionViewLayout.scrollDirection = .vertical
    }
    
    func configureCollectionView()
    {
        m_CollectionView = .init(frame: .zero, collectionViewLayout: m_CollectionViewLayout)
        
        m_CollectionView.translatesAutoresizingMaskIntoConstraints = false
        m_CollectionView.isPagingEnabled = false
        m_CollectionView.dataSource = self
        m_CollectionView.delegate = self
        m_CollectionView.showsVerticalScrollIndicator = false
        m_CollectionView.showsHorizontalScrollIndicator = false
        m_CollectionView.contentInsetAdjustmentBehavior = .never
        m_CollectionView.alwaysBounceVertical = true
        m_CollectionView.alwaysBounceHorizontal = false
        
        view.addSubview(m_CollectionView)
        
        NSLayoutConstraint.activate(
            [
                m_CollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                m_CollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                m_CollectionView.topAnchor.constraint(equalTo: view.topAnchor),
                m_CollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        )
        
        MediaPickerViewController.s_Logger.debug("Registering collection view.")
        
        m_CollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: m_CellId)
    }
    
    func setAppStateObservers()
    {
        setMoveToForegroundObserver()
    }
    
    func setMoveToForegroundObserver()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(didMoveToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}

extension MediaPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIContextMenuInteractionDelegate
{
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
    
    private var m_NumberOfSections: Int
    {
        return Int(
            (
                Double(m_FetchResult.count - 1) /
                    Double(MediaPickerViewController.s_NumberOfMediaInRow)
            ).rounded(.up)
        )
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return MediaPickerViewController.s_NumberOfMediaInRow
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return m_NumberOfSections
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        addInteractionFor(cell: cell, indexPath: indexPath)
        requestImageAt(indexPath: indexPath, targetSize: m_ItemSize)
        { image in
            self.setImagePreviewFor(cell: cell, indexPath: indexPath, image: image)
        }
        
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        
        if m_SelectedAssetIndeces.contains(assetIndex)
        {
            showSelectedAssetFor(cell: cell, isAnimated: false)
        }
        else
        {
            hideSelectedAssetFor(cell: cell, isAnimated: false)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        for subview in cell.subviews { subview.removeFromSuperview() } // Clean cell from previous images.
        cell.interactions.removeAll() // Clean cell from previous interactions, it may not be needed next.
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: m_CellId, for: indexPath)
        
        cell.backgroundColor = .clear
        cell.clipsToBounds = true
        cell.layer.cornerRadius = MediaPickerViewController.s_MediaCornerRadius
        cell.layer.cornerCurve = .continuous
        
        addAnimationTo(cell: cell)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return MediaPickerViewController.s_MinimumInteritemSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return m_ItemSize
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        let inset = MediaPickerViewController.s_MinimumInteritemSpacing / 2
        return .init(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
        m_HighlightedMediaIndexPath = indexPath
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        
        if m_SelectedAssetIndeces.contains(assetIndex)
        {
            MediaPickerViewController.s_Logger.debug("Deselecting asset at '\(assetIndex)'.")
            
            deselectAssetAt(indexPath: indexPath)
        }
        else
        {
            MediaPickerViewController.s_Logger.debug("Selecting asset at '\(assetIndex)'.")
            
            if m_SelectedAssetIndeces.count + 1 > maxSelectedAssets
            {
                MediaPickerViewController.s_Logger.debug("Cannot select asset because the max number of assets already has been selected.")
                
                return
            }
            
            selectAssetAt(indexPath: indexPath)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        .init(identifier: nil, previewProvider: mediaPreviewProvider, actionProvider: nil)
    }
}

private extension MediaPickerViewController
{
    var m_BorderWidth: CGFloat
    {
        return m_ItemSize.width * 0.02
    }
    
    var m_BorderColor: CGColor
    {
        return UIColor.systemBlue.cgColor
    }
    
    var m_ShowBorderAnimationDuration: Double
    {
        return 0.25
    }
    
    var m_HideBorderAnimationDuration: Double
    {
        return 0.2
    }
    
    func getAssetIndexAt(indexPath: IndexPath) -> Int
    {
        return indexPath.section * MediaPickerViewController.s_NumberOfMediaInRow + indexPath.row
    }
    
    func getAssetAt(indexPath: IndexPath) -> PHAsset?
    {
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        guard m_FetchResult.count - 1 >= assetIndex
        else
        {
            MediaPickerViewController.s_Logger.error("Failed to get asset at '\(assetIndex)'.")
            
            return nil
        }
        
        return m_FetchResult.object(at: assetIndex)
    }
    
    func requestImageAt(indexPath: IndexPath, targetSize: CGSize, _ completion: @escaping (_ image: UIImage?) -> Void)
    {
        guard let asset = getAssetAt(indexPath: indexPath)
        else
        {
            completion(nil)
            return
        }
        
        // Target size is bigger than the item size in order to have a decent quality, without accupying the memory with the entire image.
        let targetSize = CGSize(width: targetSize.width * 1.5, height: targetSize.height * 1.5)
        let contentMode: PHImageContentMode = .aspectFill
        
        m_ImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: m_ImageRequestOptions)
        { (image, _) in
            completion(image)
        }
    }
    
    @objc func didMoveToForeground()
    {
        fetchAssets()
        m_CollectionView.reloadData()
    }
    
    func mediaPreviewProvider() -> UIViewController
    {
        let controller = UIViewController()
        guard let highlightedMediaIndexPath = m_HighlightedMediaIndexPath, let asset = getAssetAt(indexPath: highlightedMediaIndexPath) else { return controller }
        let assetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let aspectFitSize = assetSize.aspectFitIn(containerSize: UIScreen.main.bounds.size)
        
        controller.preferredContentSize = aspectFitSize
        
        if asset.mediaType == .image
        {
            let imagePlayer = ImagePlayerViewController(imageUrl: nil, isAnimatingImage: false)
            
            if asset.playbackStyle == .imageAnimated
            {
                imagePlayer.isAnimatedImage = true
            }
            
            m_ImageManager.requestImageDataAndOrientation(for: asset, options: m_ImageRequestOptions)
            { data, _, _, _ in
                guard let data = data else { return }
                
                imagePlayer.updateImageWith(newImageData: data)
            }
            
            imagePlayer.view.translatesAutoresizingMaskIntoConstraints = false
            
            controller.addChild(imagePlayer)
            controller.view.addSubview(imagePlayer.view)
            
            NSLayoutConstraint.activate(
                [
                    imagePlayer.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                    imagePlayer.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                    imagePlayer.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                    imagePlayer.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
                ]
            )
        }
        else if asset.mediaType == .video
        {
            let videoPlayer = VideoPlayerViewController(videoUrl: nil, isVideoGravityChangeable: false, defaultVideoGravity: .resizeAspectFill)
            
            m_ImageManager.requestPlayerItem(forVideo: asset, options: m_VideoRequestOptions)
            { playerItem, _ in
                guard let playerItem = playerItem else { return }
                videoPlayer.updateCurrentVideoWith(newPlayerItem: playerItem)
            }
            
            videoPlayer.view.translatesAutoresizingMaskIntoConstraints = false
            
            controller.addChild(videoPlayer)
            controller.view.addSubview(videoPlayer.view)
            
            NSLayoutConstraint.activate(
                [
                    videoPlayer.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                    videoPlayer.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                    videoPlayer.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                    videoPlayer.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
                ]
            )
        }
        
        return controller
    }
    
    func addInteractionFor(cell: UICollectionViewCell, indexPath: IndexPath)
    {
        let interaction = UIContextMenuInteraction(delegate: self)
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        
        // We have less then max assets on section.
        if m_FetchResult.count - 1 >= assetIndex
        {
            cell.addInteraction(interaction)
        }
    }
    
    func setImagePreviewFor(cell: UICollectionViewCell, indexPath: IndexPath, image: UIImage?)
    {
        guard let image = image else { return }
        let asset = getAssetAt(indexPath: indexPath)
        let imageView = UIImageView(image: image)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        cell.addSubview(imageView)
        
        NSLayoutConstraint.activate(
            [
                imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: cell.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
            ]
        )
        
        if asset?.mediaType == .video, let assetDuration = asset?.duration
        {
            addVideoIndicatorFor(imageView: imageView, assetDuration: assetDuration)
        }
        else if asset?.mediaType == .image && asset?.playbackStyle == .imageAnimated
        {
            addGifIndicatorFor(imageView: imageView)
        }
    }
    
    func addBackgroundFor(imageView: UIImageView, indicatorView: UIView, indicatorFontSize: CGFloat, backgroundColor: UIColor)
    {
        let backgroundView = UIView()
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = backgroundColor
        backgroundView.layer.cornerRadius = indicatorFontSize * 1.5 / 2
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.masksToBounds = true
        backgroundView.clipsToBounds = true
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundView.addSubview(indicatorView)
        
        NSLayoutConstraint.activate(
            [
                indicatorView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
                indicatorView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
            ]
        )
        
        imageView.addSubview(backgroundView)
        
        let padding = -m_ItemSize.width * MediaPickerViewController.s_VideoGifIndicatorPaddingRatio
        
        NSLayoutConstraint.activate(
            [
                backgroundView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor,  constant: padding),
                backgroundView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding),
                backgroundView.heightAnchor.constraint(equalTo: indicatorView.heightAnchor, constant: indicatorFontSize / 2),
                backgroundView.widthAnchor.constraint(equalTo: indicatorView.widthAnchor, constant: indicatorFontSize)
            ]
        )
    }
    
    func addVideoIndicatorFor(imageView: UIImageView, assetDuration: TimeInterval)
    {
        let durationLabel = UILabel()
        let fontSize = m_ItemSize.width * MediaPickerViewController.s_VideoGifIndicatorPointSizeRatio
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.textColor = .white
        durationLabel.font = font
        
        if assetDuration < 60
        {
            durationLabel.text = "0:\(assetDuration.formattedDurationString)"
        }
        else
        {
            durationLabel.text = assetDuration.formattedDurationString
        }
        
        addBackgroundFor(imageView: imageView, indicatorView: durationLabel, indicatorFontSize: fontSize, backgroundColor: .systemRed)
    }
    
    func addGifIndicatorFor(imageView: UIImageView)
    {
        let symbolPointSize = m_ItemSize.width * MediaPickerViewController.s_VideoGifIndicatorPointSizeRatio
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
        let symbolImage = UIImage(systemName: "square.stack.3d.forward.dottedline", withConfiguration: symbolConfig)
        let symbolImageView = UIImageView(image: symbolImage)
        
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = .white
        
        addBackgroundFor(imageView: imageView, indicatorView: symbolImageView, indicatorFontSize: symbolPointSize, backgroundColor: .systemBlue)
    }
    
    func getCellAt(indexPath: IndexPath) -> UICollectionViewCell?
    {
        guard let cell = m_CollectionView.cellForItem(at: indexPath) else
        {
            MediaPickerViewController.s_Logger.error("Failed to get cell at '\(indexPath)'.")
            
            return nil
        }
        
        return cell
    }
    
    func showSelectedAssetFor(cell: UICollectionViewCell, isAnimated: Bool)
    {
        DispatchQueue.main.async
        {
            if isAnimated
            {
                let colorAnimation = CABasicAnimation(keyPath: "borderColor")
                
                colorAnimation.fromValue = UIColor.clear.cgColor
                colorAnimation.toValue = self.m_BorderColor
                cell.layer.borderColor = self.m_BorderColor
                
                let widthAnimation = CABasicAnimation(keyPath: "borderWidth")
                
                widthAnimation.fromValue = 0
                widthAnimation.toValue = self.m_BorderWidth
                widthAnimation.duration = self.m_ShowBorderAnimationDuration
                cell.layer.borderWidth = self.m_BorderWidth
                
                let animationGroup = CAAnimationGroup()
                
                animationGroup.duration = self.m_ShowBorderAnimationDuration
                animationGroup.animations = [colorAnimation, widthAnimation]
                animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                
                cell.layer.add(animationGroup, forKey: "ShowBorderColorWidthAnimationGroup")
            }
            else
            {
                cell.layer.borderWidth = self.m_BorderWidth
                cell.layer.borderColor = self.m_BorderColor
            }
        }
    }
    
    func hideSelectedAssetFor(cell: UICollectionViewCell, isAnimated: Bool)
    {
        DispatchQueue.main.async
        {
            if isAnimated
            {
                let colorAnimation = CABasicAnimation(keyPath: "borderColor")
                
                colorAnimation.fromValue = self.m_BorderColor
                colorAnimation.toValue = UIColor.clear.cgColor
                cell.layer.borderColor = UIColor.clear.cgColor
                
                let widthAnimation = CABasicAnimation(keyPath: "borderWidth")
                
                widthAnimation.fromValue = self.m_BorderWidth
                widthAnimation.toValue = 0
                widthAnimation.duration = self.m_HideBorderAnimationDuration
                cell.layer.borderWidth = 0
                
                let animationGroup = CAAnimationGroup()
                
                animationGroup.duration = self.m_HideBorderAnimationDuration
                animationGroup.animations = [colorAnimation, widthAnimation]
                animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                
                cell.layer.add(animationGroup, forKey: "HideBorderColorWidthAnimationGroup")
            }
            else
            {
                cell.layer.borderWidth = 0
                cell.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    func selectAssetAt(indexPath: IndexPath)
    {
        guard let asset = getAssetAt(indexPath: indexPath), let cell = getCellAt(indexPath: indexPath) else { return }
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        
        m_SelectedAssetIndeces.append(assetIndex)
        showSelectedAssetFor(cell: cell, isAnimated: true)
        delegate?.didSelectAsset(self, asset: asset, assetIndex: assetIndex)
    }
    
    func deselectAssetAt(indexPath: IndexPath)
    {
        guard let cell = getCellAt(indexPath: indexPath) else { return }
        let assetIndex = getAssetIndexAt(indexPath: indexPath)
        
        for (index, selectedAssetIndex) in m_SelectedAssetIndeces.enumerated()
        {
            if selectedAssetIndex == assetIndex
            {
                m_SelectedAssetIndeces.remove(at: index)
            }
        }
        
        hideSelectedAssetFor(cell: cell, isAnimated: true)
        delegate?.didDeselectAsset(self, assetIndex: assetIndex)
    }
    
    func addAnimationTo(cell: UICollectionViewCell)
    {
        let animationKeyPath = #keyPath(CALayer.opacity)
        let cellAnimation = CABasicAnimation(keyPath: animationKeyPath)
        
        cellAnimation.fromValue = 0.0
        cellAnimation.toValue = 1.0
        cellAnimation.duration = 0.35
        cellAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        cell.layer.add(cellAnimation, forKey: "fade")
    }
}
