//
//  EnhancementPhase.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/24/2025.
//

import SwiftUI

enum EnhancementPhase: CaseIterable {
    case rest
    case lifted
    case settled

    var scale: CGFloat {
        switch self {
        case .rest:
            return 1.0
        case .lifted:
            return 1.02
        case .settled:
            return 0.995
        }
    }

    var highlightOpacity: Double {
        switch self {
        case .rest:
            return 0.08
        case .lifted:
            return 0.22
        case .settled:
            return 0.12
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .rest:
            return 1.0
        case .lifted:
            return 1.18
        case .settled:
            return 0.98
        }
    }

    var iconOpacity: Double {
        switch self {
        case .rest:
            return 0.95
        case .lifted:
            return 1.0
        case .settled:
            return 0.88
        }
    }

    var animation: Animation? {
        switch self {
        case .rest:
            return .smooth(duration: 0.2)
        case .lifted:
            return .easeInOut(duration: 0.55)
        case .settled:
            return .spring(duration: 0.45, bounce: 0.35)
        }
    }

    var iconAnimation: Animation? {
        switch self {
        case .rest:
            return .smooth(duration: 0.2)
        case .lifted:
            return .easeInOut(duration: 0.6)
        case .settled:
            return .spring(duration: 0.45, bounce: 0.4)
        }
    }
}
