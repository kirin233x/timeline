//
//  PhotoMapView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI
import MapKit

struct PhotoMapView: View {
    let location: CLLocation
    let locationName: String?

    @State private var position: MapCameraPosition

    init(location: CLLocation, locationName: String?) {
        self.location = location
        self.locationName = locationName
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 地图
            Map(position: $position) {
                Marker("", coordinate: location.coordinate)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))

            // 位置信息
            if let name = locationName {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.red)
                    Text(name)
                        .font(.subheadline)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .foregroundStyle(.secondary)
                    Text("经度: \(String(format: "%.4f", location.coordinate.longitude)), 纬度: \(String(format: "%.4f", location.coordinate.latitude))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(Constants.cornerRadius)
    }
}

#Preview {
    let location = CLLocation(latitude: 39.9042, longitude: 116.4074) // 北京
    return PhotoMapView(location: location, locationName: "中国北京市东城区")
        .padding()
}
