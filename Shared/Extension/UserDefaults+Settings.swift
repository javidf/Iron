//
//  UserDefaults+Settings.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum SettingsKeys: String, CaseIterable {
        case weightUnit
        case massFormat
        case defaultRestTime
        case defaultRestTimeDumbbellBased
        case defaultRestTimeBarbellBased
        case keepRestTimerRunning
        case maxRepetitionsOneRepMax
        case autoBackup
        case watchCompanion
    }

    @available(*, deprecated)
    var weightUnit: WeightUnit {
        set {
            self.set(newValue.rawValue, forKey: SettingsKeys.weightUnit.rawValue)
        }
        get {
            let weightUnit = WeightUnit(rawValue: self.string(forKey: SettingsKeys.weightUnit.rawValue) ?? "")
            if let weightUnit = weightUnit {
                return weightUnit
            } else {
                let fallback = Locale.current.usesMetricSystem ? WeightUnit.metric : WeightUnit.imperial
                self.weightUnit = fallback // safe the new weight unit
                return fallback
            }
        }
    }
    
    var massFormat: MassFormat {
        set {
            self.set(newValue.rawValue, forKey: SettingsKeys.massFormat.rawValue)
        }
        get {
            let massFormat = MassFormat(rawValue: self.string(forKey: SettingsKeys.massFormat.rawValue) ?? "")
            if let massFormat = massFormat {
                return massFormat
            } else {
                let fallback: MassFormat = Locale.current.usesMetricSystem ? .metric : .imperial
                self.massFormat = fallback // safe the new mass format
                return fallback
            }
        }
    }
    
    var defaultRestTime: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTime.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTime.rawValue) as? TimeInterval ?? 90 // default 1:30
        }
    }
    
    var defaultRestTimeDumbbellBased: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTimeDumbbellBased.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTimeDumbbellBased.rawValue) as? TimeInterval ?? 150 // default 2:30
        }
    }
    
    var defaultRestTimeBarbellBased: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTimeBarbellBased.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTimeBarbellBased.rawValue) as? TimeInterval ?? 180 // default 3:00
        }
    }
    
    var keepRestTimerRunning: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.keepRestTimerRunning.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.keepRestTimerRunning.rawValue) as? Bool ?? true // default true
        }
    }
    
    var maxRepetitionsOneRepMax: Int {
        set {
            self.set(newValue, forKey: SettingsKeys.maxRepetitionsOneRepMax.rawValue)
        }
        get {
            (self.value(forKey: SettingsKeys.maxRepetitionsOneRepMax.rawValue) as? Int)?.clamped(to: maxRepetitionsOneRepMaxValues) ?? 5 // default 5
        }
    }
    
    var autoBackup: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.autoBackup.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.autoBackup.rawValue) as? Bool ?? false // default false
        }
    }
    
    var watchCompanion: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.watchCompanion.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.watchCompanion.rawValue) as? Bool ?? true // default true
        }
    }
}

let maxRepetitionsOneRepMaxValues = 1...10
