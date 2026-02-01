//
//  LocationService.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import CoreLocation
import UIKit
import Combine

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let geocoder = CLGeocoder()
    private var locationCache: [String: CLPlacemark] = [:]

    override init() {
        super.init()
    }

    /// 反向地理编码获取位置名称
    func reverseGeocode(location: CLLocation) async -> String? {
        let placemark = await reverseGeocodeDetailed(location: location)

        if let city = placemark?.locality, let area = placemark?.subLocality {
            return "\(city) \(area)"
        } else if let city = placemark?.locality {
            return city
        } else if let name = placemark?.name {
            return name
        }

        return nil
    }

    /// 获取详细地址信息
    func reverseGeocodeDetailed(location: CLLocation) async -> CLPlacemark? {
        // 创建缓存键
        let cacheKey = "\(location.coordinate.latitude),\(location.coordinate.longitude)"

        // 检查缓存
        if let cached = locationCache[cacheKey] {
            return cached
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                locationCache[cacheKey] = placemark
                return placemark
            }
        } catch {
            print("反向地理编码失败: \(error.localizedDescription)")
        }

        return nil
    }

    /// 获取格式化的地址字符串
    func formatAddress(from location: CLLocation) async -> String {
        let placemark = await reverseGeocodeDetailed(location: location)

        var components: [String] = []

        if let country = placemark?.country {
            components.append(country)
        }

        if let administrativeArea = placemark?.administrativeArea {
            components.append(administrativeArea)
        }

        if let locality = placemark?.locality {
            components.append(locality)
        }

        if let subLocality = placemark?.subLocality {
            components.append(subLocality)
        }

        if let name = placemark?.name {
            components.append(name)
        }

        return components.isEmpty ? "未知位置" : components.joined(separator: "")
    }

    /// 清除缓存
    func clearCache() {
        locationCache.removeAll()
    }
}
