//
//  Constants.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftUI

struct Constants {
    // MARK: - UI Constants
    static let timelineLineWidth: CGFloat = 2
    static let timelineDotSize: CGFloat = 12
    static let photoThumbnailSize: CGFloat = 80
    static let cornerRadius: CGFloat = 12

    // MARK: - Date Formats
    static let dateFormatDisplay = "yyyy年MM月dd日 HH:mm"
    static let dateFormatShort = "yyyy年MM月dd日"

    // MARK: - Animation
    static let animationDuration: Double = 0.3
}

struct AppColor {
    static let primary = Color.blue
    static let milestone = Color.orange
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
}
