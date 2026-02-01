//
//  EXIFService.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import UIKit
import Photos
import ImageIO
import CoreLocation

struct EXIFData {
    let dateTimeOriginal: Date?
    let cameraModel: String?
    let lensModel: String?
    let iso: Double?
    let aperture: Double?
    let shutterSpeed: Double?
    let focalLength: Double?
    let location: CLLocation?
}

struct EXIFService {
    /// 从 PHAsset 读取 EXIF DateTimeOriginal
    static func extractDateTimeOriginal(from asset: PHAsset) -> Date? {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return nil
        }

        if resource.type == .photo || resource.type == .video {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true

            var exifDate: Date?

            let semaphore = DispatchSemaphore(value: 0)
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data = data,
                   let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                   let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {

                    if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
                       let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                        exifDate = self.parseExifDate(dateString)
                    }
                }
                semaphore.signal()
            }

            semaphore.wait()
            return exifDate
        }

        return nil
    }

    /// 读取拍摄设备信息
    static func extractCameraInfo(from asset: PHAsset) -> (model: String?, lens: String?) {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return (nil, nil)
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        var cameraModel: String?
        var lensModel: String?

        let semaphore = DispatchSemaphore(value: 0)
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data,
               let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {

                // 读取相机型号
                if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
                    cameraModel = tiffDict[kCGImagePropertyTIFFModel as String] as? String
                }

                // 读取镜头信息
                if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                    lensModel = exifDict[kCGImagePropertyExifLensModel as String] as? String
                }
            }
            semaphore.signal()
        }

        semaphore.wait()
        return (cameraModel, lensModel)
    }

    /// 读取 GPS 信息
    static func extractLocation(from asset: PHAsset) -> CLLocation? {
        guard let location = asset.location else {
            // 如果 PHAsset 没有位置信息，尝试从 EXIF 读取
            return extractLocationFromEXIF(asset: asset)
        }
        return location
    }

    /// 从 EXIF 数据中提取 GPS 信息
    private static func extractLocationFromEXIF(asset: PHAsset) -> CLLocation? {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return nil
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        var location: CLLocation?

        let semaphore = DispatchSemaphore(value: 0)
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data,
               let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {

                if let gpsDict = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
                   let latitude = parseGPSCoordinate(from: gpsDict, key: kCGImagePropertyGPSLatitude as String),
                   let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
                   let longitude = parseGPSCoordinate(from: gpsDict, key: kCGImagePropertyGPSLongitude as String),
                   let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String {

                    let lat = latitudeRef == "S" ? -latitude : latitude
                    let lon = longitudeRef == "W" ? -longitude : longitude
                    location = CLLocation(latitude: lat, longitude: lon)
                }
            }
            semaphore.signal()
        }

        semaphore.wait()
        return location
    }

    /// 读取完整 EXIF 数据
    static func extractAllEXIF(from asset: PHAsset) -> EXIFData {
        let dateTimeOriginal = extractDateTimeOriginal(from: asset)
        let (cameraModel, lensModel) = extractCameraInfo(from: asset)
        let location = extractLocation(from: asset)

        // 读取拍摄参数
        let (iso, aperture, shutterSpeed, focalLength) = extractCameraParameters(from: asset)

        return EXIFData(
            dateTimeOriginal: dateTimeOriginal,
            cameraModel: cameraModel,
            lensModel: lensModel,
            iso: iso,
            aperture: aperture,
            shutterSpeed: shutterSpeed,
            focalLength: focalLength,
            location: location
        )
    }

    /// 读取拍摄参数
    private static func extractCameraParameters(from asset: PHAsset) -> (iso: Double?, aperture: Double?, shutterSpeed: Double?, focalLength: Double?) {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return (nil, nil, nil, nil)
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        var iso: Double?
        var aperture: Double?
        var shutterSpeed: Double?
        var focalLength: Double?

        let semaphore = DispatchSemaphore(value: 0)
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data,
               let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {

                if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                    iso = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? Double
                    aperture = exifDict[kCGImagePropertyExifFNumber as String] as? Double
                    shutterSpeed = exifDict[kCGImagePropertyExifExposureTime as String] as? Double
                    focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double
                }
            }
            semaphore.signal()
        }

        semaphore.wait()
        return (iso, aperture, shutterSpeed, focalLength)
    }

    // MARK: - Helper Methods

    /// 解析 EXIF 日期格式 "yyyy:MM:dd HH:mm:ss"
    private static func parseExifDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }

    /// 解析 GPS 坐标
    private static func parseGPSCoordinate(from dict: [String: Any], key: String) -> Double? {
        guard let coordinateArray = dict[key] as? [AnyObject],
              coordinateArray.count == 3,
              let degrees = coordinateArray[0] as? Double,
              let minutes = coordinateArray[1] as? Double,
              let seconds = coordinateArray[2] as? Double else {
            return nil
        }

        return degrees + (minutes / 60.0) + (seconds / 3600.0)
    }

    /// 从 Data 解析 EXIF 数据（用于 PhotosPicker）
    static func extractEXIF(from data: Data) -> EXIFData {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return EXIFData(
                dateTimeOriginal: nil,
                cameraModel: nil,
                lensModel: nil,
                iso: nil,
                aperture: nil,
                shutterSpeed: nil,
                focalLength: nil,
                location: nil
            )
        }

        // 提取拍摄日期
        var dateTimeOriginal: Date?
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            dateTimeOriginal = parseExifDate(dateString)
        }

        // 提取相机型号
        var cameraModel: String?
        var lensModel: String?
        if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            cameraModel = tiffDict[kCGImagePropertyTIFFModel as String] as? String
        }
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            lensModel = exifDict[kCGImagePropertyExifLensModel as String] as? String
        }

        // 提取拍摄参数
        var iso: Double?
        var aperture: Double?
        var shutterSpeed: Double?
        var focalLength: Double?
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            iso = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? Double
            aperture = exifDict[kCGImagePropertyExifFNumber as String] as? Double
            shutterSpeed = exifDict[kCGImagePropertyExifExposureTime as String] as? Double
            focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double
        }

        // 提取 GPS 位置
        var location: CLLocation?
        if let gpsDict = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let latitude = parseGPSCoordinate(from: gpsDict, key: kCGImagePropertyGPSLatitude as String),
           let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let longitude = parseGPSCoordinate(from: gpsDict, key: kCGImagePropertyGPSLongitude as String),
           let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String {

            let lat = latitudeRef == "S" ? -latitude : latitude
            let lon = longitudeRef == "W" ? -longitude : longitude
            location = CLLocation(latitude: lat, longitude: lon)
        }

        return EXIFData(
            dateTimeOriginal: dateTimeOriginal,
            cameraModel: cameraModel,
            lensModel: lensModel,
            iso: iso,
            aperture: aperture,
            shutterSpeed: shutterSpeed,
            focalLength: focalLength,
            location: location
        )
    }
}
