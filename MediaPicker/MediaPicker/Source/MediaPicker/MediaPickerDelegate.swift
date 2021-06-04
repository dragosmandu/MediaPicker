//
//
//  Workspace: MediaPicker
//  MacOS Version: 11.4
//			
//  File Name: MediaPickerDelegate.swift
//  Creation: 6/4/21 3:27 PM
//
//  Author: Dragos-Costin Mandu
//
//


import PhotosUI

public protocol MediaPickerDelegate
{
    
    /// Called when the user selects a new asset in library.
    /// - Parameters:
    ///   - assetIndex: The index for asset in collection view.
    func didSelectAsset(_ mediaPickerController: MediaPickerViewController, asset: PHAsset, assetIndex: Int)
    
    /// Called when the user deselects a selected item.
    /// - Parameters:
    ///   - assetIndex: The index for asset in collection view.
    func didDeselectAsset(_ mediaPickerController: MediaPickerViewController, assetIndex: Int)
}
