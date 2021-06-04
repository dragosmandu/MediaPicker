//
//
//  Workspace: MediaPicker
//  MacOS Version: 11.4
//			
//  File Name: MediaPickerTestViewController.swift
//  Creation: 6/4/21 3:43 PM
//
//  Author: Dragos-Costin Mandu
//
//


import UIKit
import MediaPicker
import PhotosUI

class MediaPickerTestViewController: UIViewController, MediaPickerDelegate
{
    let m_MediaPickerController = MediaPickerViewController()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addChild(m_MediaPickerController)
        view.addSubview(m_MediaPickerController.view)
        view.backgroundColor = .white
        
        m_MediaPickerController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                m_MediaPickerController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
                m_MediaPickerController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
            ]
        )
    }
    
    func didSelectAsset(_ mediaPickerController: MediaPickerViewController, asset: PHAsset, assetIndex: Int)
    {
        print("Selected asset: '\(assetIndex)'")
    }
    
    func didDeselectAsset(_ mediaPickerController: MediaPickerViewController, assetIndex: Int)
    {
        print("Deselected asset: '\(assetIndex)'")
    }
}

