import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
public struct Workout: Identifiable, Equatable, Hashable {
    public var id: Int64?
    public var uuid: UUID = UUID()
    public var start: Date
    public var end: Date?
    public var title: String?
    public var comment: String?
    public var isActive: Bool = false
}

extension Workout {
    public static let workoutExercises = hasMany(WorkoutExercise.self).order(WorkoutExercise.Columns.order)
    
    public var workoutExercises: QueryInterfaceRequest<WorkoutExercise> {
        request(for: Self.workoutExercises).order()
    }
}

extension Workout {
    public static func new(start: Date) -> Workout {
        Workout(start: start)
    }
    
    static func makeRandom() -> Workout {
        let daysAgo = Double.random(in: 1...60)
        let duration = Double.random(in: 45...130)
        return Workout(start: Date(timeIntervalSinceNow: -60*duration-daysAgo*60*60*24), end: Date(timeIntervalSinceNow: -daysAgo*60*60*24), title: randomTitle(), comment: randomComment(), isActive: false)
    }
    
    private static func randomTitle() -> String {
        ["Upper Body", "Lower Body", "Push", "Pull", "Legs"].randomElement()!
    }
    
    private static func randomComment() -> String? {
        nil
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Workout: Codable, FetchableRecord, MutablePersistableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let uuid = Column(CodingKeys.uuid)
        public static let start = Column(CodingKeys.start)
        public static let end = Column(CodingKeys.end)
        public static let title = Column(CodingKeys.title)
        public static let comment = Column(CodingKeys.comment)
        public static let isActive = Column(CodingKeys.isActive)
    }
    
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == Workout {
    public func orderByStart() -> Self {
        order(Workout.Columns.start.desc)
    }
}