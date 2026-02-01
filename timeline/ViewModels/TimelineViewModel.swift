//
//  TimelineViewModel.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import CoreLocation
import Photos

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var baby: Baby?
    @Published var timelineSections: [TimelineSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPhotos: Set<String> = []
    @Published var showPhotoPicker = false

    private let photoService = PhotoService()
    private let exifService = EXIFService.self

    func loadTimeline(baby: Baby) {
        self.baby = baby
        isLoading = true
        defer { isLoading = false }

        guard let photos = baby.photos, !photos.isEmpty else {
            timelineSections = []
            return
        }

        // 按拍摄日期排序
        let sortedPhotos = photos.sorted { $0.captureDate < $1.captureDate }

        // 构建时间线分组
        timelineSections = buildSections(from: sortedPhotos, baby: baby)
    }

    func addPhotos(identifiers: [String], context: ModelContext) async {
        guard let baby = baby else { return }

        isLoading = true
        defer { isLoading = false }

        for identifier in identifiers {
            guard let asset = photoService.fetchAsset(for: identifier) else {
                continue
            }

            let exifData = exifService.extractAllEXIF(from: asset)

            let timelinePhoto = TimelinePhoto(
                localIdentifier: identifier,
                exifDate: exifData.dateTimeOriginal,
                assetDate: asset.creationDate ?? Date(),
                baby: baby
            )

            if let location = exifData.location {
                timelinePhoto.latitude = location.coordinate.latitude
                timelinePhoto.longitude = location.coordinate.longitude
            }

            timelinePhoto.cameraModel = exifData.cameraModel
            timelinePhoto.lensModel = exifData.lensModel

            context.insert(timelinePhoto)
        }

        do {
            try context.save()
            loadTimeline(baby: baby)
        } catch {
            errorMessage = "添加照片失败: \(error.localizedDescription)"
        }
    }

    private func buildSections(from photos: [TimelinePhoto], baby: Baby) -> [TimelineSection] {
        var sections: [TimelineSection] = []
        var currentPhotos: [TimelinePhoto] = []
        var currentDate: Date?
        var currentAgeInfo: AgeInfo?

        let calendar = Calendar.current

        for photo in photos {
            let ageInfo = photo.babyAge(birthDate: baby.birthDate)
            let photoDate = photo.captureDate

            // 检查是否需要创建新的分组
            if let current = currentDate {
                let daysBetween = calendar.dateComponents([.day], from: current, to: photoDate).day ?? 0

                // 如果日期不同或者年龄信息变化明显，创建新分组
                if daysBetween > 0 || (currentAgeInfo?.displayText != ageInfo.displayText) {
                    // 保存当前分组
                    if !currentPhotos.isEmpty, let date = currentDate, let age = currentAgeInfo {
                        sections.append(TimelineSection(date: date, ageInfo: age, photos: currentPhotos))
                    }

                    // 开始新分组
                    currentPhotos = [photo]
                    currentDate = photoDate
                    currentAgeInfo = ageInfo
                } else {
                    // 添加到当前分组
                    currentPhotos.append(photo)
                }
            } else {
                // 第一张照片
                currentPhotos = [photo]
                currentDate = photoDate
                currentAgeInfo = ageInfo
            }
        }

        // 添加最后一个分组
        if !currentPhotos.isEmpty, let date = currentDate, let age = currentAgeInfo {
            sections.append(TimelineSection(date: date, ageInfo: age, photos: currentPhotos))
        }

        return sections
    }

    func deletePhoto(_ photo: TimelinePhoto, context: ModelContext) {
        context.delete(photo)
        if let baby = baby {
            loadTimeline(baby: baby)
        }
    }

    func addSavedPhotos(photos: [SavedPhoto], to baby: Baby, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        for savedPhoto in photos {
            let exifData = savedPhoto.exifData

            let timelinePhoto = TimelinePhoto(
                localIdentifier: savedPhoto.localPath,
                exifDate: exifData?.dateTimeOriginal,
                assetDate: Date(),
                baby: baby
            )

            if let location = exifData?.location {
                timelinePhoto.latitude = location.coordinate.latitude
                timelinePhoto.longitude = location.coordinate.longitude
            }

            timelinePhoto.cameraModel = exifData?.cameraModel
            timelinePhoto.lensModel = exifData?.lensModel

            context.insert(timelinePhoto)
        }

        do {
            try context.save()
            loadTimeline(baby: baby)
            print("✅ 成功添加 \(photos.count) 张照片")
        } catch {
            errorMessage = "添加照片失败: \(error.localizedDescription)"
            print("❌ 添加照片失败: \(error)")
        }
    }

    // 新增：支持Timeline的loadTimeline方法
    func loadTimeline(timeline: Timeline) {
        isLoading = true
        defer { isLoading = false }

        let photos = timeline.photos

        guard !photos.isEmpty else {
            timelineSections = []
            return
        }

        // 按拍摄日期排序
        let sortedPhotos = photos.sorted { $0.captureDate < $1.captureDate }

        // 构建时间线分组
        timelineSections = buildSections(from: sortedPhotos, timeline: timeline)
    }

    // 新增：支持Timeline的addSavedPhotos方法
    func addSavedPhotos(photos: [SavedPhoto], to timeline: Timeline, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        for savedPhoto in photos {
            let exifData = savedPhoto.exifData

            let timelinePhoto = TimelinePhoto(
                localIdentifier: savedPhoto.localPath,
                exifDate: exifData?.dateTimeOriginal,
                assetDate: Date(),
                timeline: timeline
            )

            if let location = exifData?.location {
                timelinePhoto.latitude = location.coordinate.latitude
                timelinePhoto.longitude = location.coordinate.longitude
            }

            timelinePhoto.cameraModel = exifData?.cameraModel
            timelinePhoto.lensModel = exifData?.lensModel

            context.insert(timelinePhoto)
        }

        do {
            try context.save()
            loadTimeline(timeline: timeline)
            print("✅ 成功添加 \(photos.count) 张照片到时间线: \(timeline.title)")
        } catch {
            errorMessage = "添加照片失败: \(error.localizedDescription)"
            print("❌ 添加照片失败: \(error)")
        }
    }

    // 新增：支持Timeline的buildSections方法
    private func buildSections(from photos: [TimelinePhoto], timeline: Timeline) -> [TimelineSection] {
        var sections: [TimelineSection] = []
        var currentPhotos: [TimelinePhoto] = []
        var currentDate: Date?
        var currentAgeInfo: AgeInfo?

        let calendar = Calendar.current

        for photo in photos {
            let ageInfo = timeline.ageInfo(at: photo.captureDate)
            let photoDate = photo.captureDate

            // 检查是否需要创建新的分组
            if let current = currentDate {
                let daysBetween = calendar.dateComponents([.day], from: current, to: photoDate).day ?? 0

                // 如果日期不同或者年龄信息变化明显，创建新分组
                if daysBetween > 0 || (currentAgeInfo?.displayText != ageInfo.displayText) {
                    // 保存当前分组
                    if !currentPhotos.isEmpty, let date = currentDate, let age = currentAgeInfo {
                        sections.append(TimelineSection(date: date, ageInfo: age, photos: currentPhotos))
                    }

                    // 开始新分组
                    currentPhotos = [photo]
                    currentDate = photoDate
                    currentAgeInfo = ageInfo
                } else {
                    // 添加到当前分组
                    currentPhotos.append(photo)
                }
            } else {
                // 第一组
                currentPhotos = [photo]
                currentDate = photoDate
                currentAgeInfo = ageInfo
            }
        }

        // 添加最后一组
        if !currentPhotos.isEmpty, let date = currentDate, let age = currentAgeInfo {
            sections.append(TimelineSection(date: date, ageInfo: age, photos: currentPhotos))
        }

        return sections
    }
}

struct TimelineSection: Identifiable {
    let id = UUID()
    let date: Date
    let ageInfo: AgeInfo
    let photos: [TimelinePhoto]
}
