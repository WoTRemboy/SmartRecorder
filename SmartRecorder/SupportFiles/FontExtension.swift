//
//  FontExtension.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 23.10.2025.
//
import SwiftUI

extension Font {
    static func body() -> Font? {
        Font.system(size: 14)
    }
    
    static func title() -> Font? {
        Font.system(size: 22, weight: .bold)
    }
    
    static func title2(_ weight: Font.Weight = .regular) -> Font? {
        Font.system(size: 20, weight: weight)
        
    }
    
    static func buttonTitle() -> Font? {
        Font.system(size: 40, weight: .bold)
    }
    
    static func buttonTitle2() -> Font? {
        Font.system(size: 30, weight: .bold)
    }
    
    static func caption(_ weight: Font.Weight = .regular) -> Font? {
        Font.system(size: 12.5, weight: weight)
    }
    
    
}
