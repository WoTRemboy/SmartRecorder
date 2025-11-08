//
//  FontExtension.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 23.10.2025.
//
import SwiftUI

extension Font {
    static func largeTitle() -> Font? {
        Font.system(size: 35, weight: .bold)
    }
    
    static func body() -> Font? {
        Font.system(size: 14)
    }
}
