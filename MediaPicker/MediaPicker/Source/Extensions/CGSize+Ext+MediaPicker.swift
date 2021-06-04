//
//
//  Workspace: MediaPicker
//  MacOS Version: 11.4
//			
//  File Name: CGSize+Ext+MediaPicker.swift
//  Creation: 6/4/21 3:32 PM
//
//  Author: Dragos-Costin Mandu
//
//


import CoreGraphics

public extension CGSize
{
    // MARK: - Methods
    
    /// Calculates the size, that fits the given containerSize, in which the current size should fit in and ocupy as much space as possible.
    /// - Parameter containerSize: The size of the container in which the current size should fit in.
    func aspectFitIn(containerSize: CGSize) -> CGSize
    {
        let widthScaleRatio = containerSize.width / width
        let heightScaleRatio = containerSize.height / height
        let scaleFactor = min(widthScaleRatio, heightScaleRatio)
        let aspectFitSize = CGSize(width: width * scaleFactor, height: height * scaleFactor)
        
        return aspectFitSize
    }
}
