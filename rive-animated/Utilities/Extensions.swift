//
//  Extensions.swift
//  rive-animated
//
//  Created by vijay verma on 17/02/25.
//

import Foundation
import SwiftUI

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this extension for color interpolation
extension Array where Element == Gradient.Stop {
    func interpolatedColor(at location: CGFloat) -> Color {
        guard !isEmpty else { return .black }
        guard count > 1 else { return first?.color ?? .black }
        
        for (index, stop) in self.enumerated() {
            if location <= stop.location {
                if index == 0 { return stop.color }
                let previousStop = self[index - 1]
                let fraction = (location - previousStop.location) / (stop.location - previousStop.location)
                return Color.lerp(from: previousStop.color, to: stop.color, fraction: fraction)
            }
        }
        
        return last?.color ?? .black
    }
}



extension Color {
    static func lerp(from start: Color, to end: Color, fraction: CGFloat) -> Color {
        let startComponents = start.cgColor?.components ?? [0, 0, 0, 1]
        let endComponents = end.cgColor?.components ?? [0, 0, 0, 1]
        
        let red = startComponents[0] + (endComponents[0] - startComponents[0]) * fraction
        let green = startComponents[1] + (endComponents[1] - startComponents[1]) * fraction
        let blue = startComponents[2] + (endComponents[2] - startComponents[2]) * fraction
        let alpha = startComponents[3] + (endComponents[3] - startComponents[3]) * fraction
        
        return Color(.sRGB, red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}


// Layout debuger
struct DebugLayoutModifier: ViewModifier {
    enum DebugMode {
        case fillOnly
        case outlineOnly
        case both
    }
    
    var debug: Bool
    var mode: DebugMode = .both
    
    func body(content: Content) -> some View {
        content
            .background(
                debug && (mode == .fillOnly || mode == .both) ? Color.red : Color.clear
            )
            .border(
                debug && (mode == .outlineOnly || mode == .both) ? Color.blue : Color.clear,
                width: 2
            )
    }
}
