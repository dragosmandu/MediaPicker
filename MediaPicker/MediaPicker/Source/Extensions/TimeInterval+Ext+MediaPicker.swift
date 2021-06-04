//
//
//  Workspace: MediaPicker
//  MacOS Version: 11.4
//			
//  File Name: TimeInterval+Ext+MediaPicker.swift
//  Creation: 6/4/21 3:34 PM
//
//  Author: Dragos-Costin Mandu
//
//


import Foundation
import os

public extension TimeInterval
{
    /// The formatted duration of the current time interval as a String, with h:min:sec format.
    /// ```
    /// If the interval is lower than 0, will return an empty String.
    /// ```
    var formattedDurationString: String
    {
        var formattedDurationString: String = ""
        
        guard !isInfinite, !isNaN else { return formattedDurationString }
        
        let seconds = Int(self)
        
        if self >= 0
        {
            let hours = seconds / 3600
            let minutes = (seconds / 60) % 60
            let seconds = seconds % 60
            
            if hours == 0 && minutes == 0
            {
                formattedDurationString = String(format:"%02i", seconds)
            }
            else if hours == 0
            {
                formattedDurationString = String(format:"%02i:%02i", minutes, seconds)
            }
            else
            {
                formattedDurationString = String(format:"%02i:%02i:%02i", hours, minutes, seconds)
            }
        }
        
        return formattedDurationString
    }
}

