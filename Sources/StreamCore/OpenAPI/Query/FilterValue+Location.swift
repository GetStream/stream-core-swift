//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// A circular geographic region defined by a center point and a radius.
///
/// Use `CircularRegion` to represent a circular area on Earth's surface, typically used for location-based
/// queries such as finding all points within a certain distance from a center coordinate.
///
/// ## Example
/// ```swift
/// let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
/// let region = CircularRegion(center: center, radiusInMeters: 5000)
/// ```
public struct CircularRegion {
    /// The center coordinate of the circular region.
    public let center: CLLocationCoordinate2D
    
    /// The radius of the circular region in meters.
    public let radius: Double
    
    /// Creates a circular region with the specified center and radius.
    ///
    /// - Parameters:
    ///   - center: The center coordinate of the circular region.
    ///   - radiusInMeters: The radius of the region in meters.
    public init(center: CLLocationCoordinate2D, radiusInMeters: Double) {
        self.center = center
        self.radius = radiusInMeters
    }
    
    /// Creates a circular region with the specified center and radius.
    ///
    /// - Parameters:
    ///   - center: The center coordinate of the circular region.
    ///   - radiusInKM: The radius of the region in kilometers. This value is automatically converted to meters.
    public init(center: CLLocationCoordinate2D, radiusInKM: Double) {
        self.center = center
        self.radius = radiusInKM * 1000.0
    }
}

extension CircularRegion: FilterValue {
    static let rawJSONDistanceInKmKey = "distance"
    
    init?(from rawJSON: [String: RawJSON]) {
        guard let center = CLLocationCoordinate2D(from: rawJSON) else { return nil }
        guard let distanceInKm = rawJSON[Self.rawJSONDistanceInKmKey]?.numberValue else { return nil }
        self.center = center
        self.radius = distanceInKm * 1000.0
    }
    
    public var rawJSON: RawJSON {
        [
            CLLocationCoordinate2D.rawJSONLatitudeKey: .number(center.latitude),
            CLLocationCoordinate2D.rawJSONLongitudeKey: .number(center.longitude),
            Self.rawJSONDistanceInKmKey: .number(radius / 1000.0)
        ]
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let coordinateLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = centerLocation.distance(from: coordinateLocation)
        return distance <= radius
    }
}

/// A rectangular geographic region defined by northeast and southwest corner coordinates.
///
/// Use `BoundingBox` to represent a rectangular area on Earth's surface, typically used for location-based
/// queries such as finding all points within a specific geographic boundary.
///
/// The bounding box is defined by two corner coordinates:
/// - `northeast`: The northeast (top-right) corner of the rectangle
/// - `southwest`: The southwest (bottom-left) corner of the rectangle
///
/// ## Example
/// ```swift
/// let ne = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
/// let sw = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
/// let boundingBox = BoundingBox(northeast: ne, southwest: sw)
/// ```
public struct BoundingBox {
    /// The northeast (top-right) corner coordinate of the bounding box.
    public let northeast: CLLocationCoordinate2D
    
    /// The southwest (bottom-left) corner coordinate of the bounding box.
    public let southwest: CLLocationCoordinate2D
    
    /// Creates a bounding box with the specified corner coordinates.
    ///
    /// - Parameters:
    ///   - northeast: The northeast (top-right) corner coordinate.
    ///   - southwest: The southwest (bottom-left) corner coordinate.
    public init(northeast: CLLocationCoordinate2D, southwest: CLLocationCoordinate2D) {
        self.northeast = northeast
        self.southwest = southwest
    }
}

extension BoundingBox: FilterValue {
    static let rawJSONNortheastLatitudeKey = "ne_lat"
    static let rawJSONNortheastLongitudeKey = "ne_lng"
    static let rawJSONSouthwestLatitudeKey = "sw_lat"
    static let rawJSONSouthwestLongitudeKey = "sw_lng"
    
    init?(from rawJSON: [String: RawJSON]) {
        guard let neLatitude = rawJSON[Self.rawJSONNortheastLatitudeKey]?.numberValue else { return nil }
        guard let neLongitude = rawJSON[Self.rawJSONNortheastLongitudeKey]?.numberValue else { return nil }
        guard let swLatitude = rawJSON[Self.rawJSONSouthwestLatitudeKey]?.numberValue else { return nil }
        guard let swLongitude = rawJSON[Self.rawJSONSouthwestLongitudeKey]?.numberValue else { return nil }
        northeast = CLLocationCoordinate2D(latitude: neLatitude, longitude: neLongitude)
        southwest = CLLocationCoordinate2D(latitude: swLatitude, longitude: swLongitude)
    }
    
    public var rawJSON: RawJSON {
        [
            Self.rawJSONNortheastLatitudeKey: .number(northeast.latitude),
            Self.rawJSONNortheastLongitudeKey: .number(northeast.longitude),
            Self.rawJSONSouthwestLatitudeKey: .number(southwest.latitude),
            Self.rawJSONSouthwestLongitudeKey: .number(southwest.longitude)
        ]
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard coordinate.latitude >= southwest.latitude && coordinate.latitude <= northeast.latitude else { return false }
        guard coordinate.longitude >= southwest.longitude && coordinate.longitude <= northeast.longitude else { return false }
        return true
    }
}

extension CLLocationCoordinate2D: FilterValue {
    static let rawJSONLatitudeKey = "lat"
    static let rawJSONLongitudeKey = "lng"
    
    init?(from rawJSON: [String: RawJSON]) {
        guard let latitude = rawJSON[CLLocationCoordinate2D.rawJSONLatitudeKey]?.numberValue else { return nil }
        guard let longitude = rawJSON[CLLocationCoordinate2D.rawJSONLongitudeKey]?.numberValue else { return nil }
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public var rawJSON: RawJSON {
        .dictionary([
            Self.rawJSONLatitudeKey: .number(latitude),
            Self.rawJSONLongitudeKey: .number(longitude)
        ])
    }
}
