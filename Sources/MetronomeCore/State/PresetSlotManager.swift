import Foundation

/// A self-contained configuration preset for the metronome.
public struct MetronomePreset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var bpm: Double
    public var timeSignature: TimeSignature
    public var subdivision: Subdivision
    public var grooveFeel: GrooveFeel
    public var downbeatPitchMultiplier: Float
    public var timbre: Timbre
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        bpm: Double = 120.0,
        timeSignature: TimeSignature = .common,
        subdivision: Subdivision = .quarter,
        grooveFeel: GrooveFeel = .straight,
        downbeatPitchMultiplier: Float = 1.5,
        timbre: Timbre = .woodblock,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.subdivision = subdivision
        self.grooveFeel = grooveFeel
        self.downbeatPitchMultiplier = downbeatPitchMultiplier
        self.timbre = timbre
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Manages dynamic preset slots with add, remove, reorder, update, recall, and persistence.
public final class PresetSlotManager: @unchecked Sendable {
    private let lock = NSLock()
    private let userDefaults: UserDefaults?
    private let storageKey: String

    private var slots: [MetronomePreset] = []
    private var selectedPresetId: UUID?

    public init(
        userDefaults: UserDefaults? = .standard,
        storageKey: String = "Metronome_PresetSlots",
        initialDefaultPresets: [MetronomePreset]? = nil
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey

        loadPersistedSlots()

        if slots.isEmpty, let defaults = initialDefaultPresets, !defaults.isEmpty {
            slots = defaults
            savePersistedSlots()
        }
    }

    /// Factory providing standard factory default presets.
    public static var defaultPresets: [MetronomePreset] {
        [
            MetronomePreset(name: "Standard 4/4", bpm: 120.0, timeSignature: .common, subdivision: .quarter, timbre: .woodblock),
            MetronomePreset(name: "Waltz 3/4", bpm: 140.0, timeSignature: .waltz, subdivision: .quarter, timbre: .woodblock),
            MetronomePreset(name: "March 2/4", bpm: 110.0, timeSignature: .march, subdivision: .eighth, timbre: .digitalBeep),
            MetronomePreset(name: "Fast Swing", bpm: 160.0, timeSignature: .common, subdivision: .eighth, grooveFeel: .standardSwing, timbre: .rimshot),
            MetronomePreset(name: "Compound 6/8", bpm: 90.0, timeSignature: .sixEight, subdivision: .eighth, timbre: .studioClick)
        ]
    }

    private func loadPersistedSlots() {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MetronomePreset].self, from: data) else {
            return
        }
        self.slots = decoded
    }

    private func savePersistedSlots() {
        guard let defaults = userDefaults,
              let data = try? JSONEncoder().encode(slots) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    /// Returns a copy of all current presets in order.
    public var allPresets: [MetronomePreset] {
        lock.lock()
        defer { lock.unlock() }
        return slots
    }

    /// Number of stored preset slots.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return slots.count
    }

    /// Currently active or recalled preset.
    public var selectedPreset: MetronomePreset? {
        lock.lock()
        defer { lock.unlock() }
        guard let id = selectedPresetId else { return nil }
        return slots.first { $0.id == id }
    }

    /// Adds a new preset slot. If index is omitted, appends to the end.
    public func add(_ preset: MetronomePreset, at index: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = index, idx >= 0, idx <= slots.count {
            slots.insert(preset, at: idx)
        } else {
            slots.append(preset)
        }
        savePersistedSlots()
    }

    /// Removes a preset by its unique ID.
    @discardableResult
    public func remove(id: UUID) -> MetronomePreset? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return nil }
        let removed = slots.remove(at: index)
        if selectedPresetId == id {
            selectedPresetId = nil
        }
        savePersistedSlots()
        return removed
    }

    /// Removes a preset at a specific slot index.
    @discardableResult
    public func remove(at index: Int) -> MetronomePreset? {
        lock.lock()
        defer { lock.unlock() }
        guard index >= 0, index < slots.count else { return nil }
        let removed = slots.remove(at: index)
        if selectedPresetId == removed.id {
            selectedPresetId = nil
        }
        savePersistedSlots()
        return removed
    }

    /// Updates an existing preset with matching ID.
    @discardableResult
    public func update(_ preset: MetronomePreset) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = slots.firstIndex(where: { $0.id == preset.id }) else { return false }
        var updated = preset
        updated.updatedAt = Date()
        slots[index] = updated
        savePersistedSlots()
        return true
    }

    /// Recalls/selects a preset by its ID.
    public func recall(id: UUID) -> MetronomePreset? {
        lock.lock()
        defer { lock.unlock() }
        guard let preset = slots.first(where: { $0.id == id }) else { return nil }
        selectedPresetId = id
        return preset
    }

    /// Recalls/selects a preset at a specific slot index.
    public func recall(at index: Int) -> MetronomePreset? {
        lock.lock()
        defer { lock.unlock() }
        guard index >= 0, index < slots.count else { return nil }
        let preset = slots[index]
        selectedPresetId = preset.id
        return preset
    }

    /// Reorders preset slots from source index to destination index.
    public func move(from sourceIndex: Int, to destinationIndex: Int) {
        lock.lock()
        defer { lock.unlock() }
        guard sourceIndex >= 0, sourceIndex < slots.count,
              destinationIndex >= 0, destinationIndex < slots.count,
              sourceIndex != destinationIndex else {
            return
        }
        let item = slots.remove(at: sourceIndex)
        slots.insert(item, at: destinationIndex)
        savePersistedSlots()
    }

    /// Exports all presets as a JSON string.
    public func exportToJSON() throws -> String {
        lock.lock()
        defer { lock.unlock() }
        let encoder = JSONEncoder()
        if #available(macOS 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(slots)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return jsonString
    }

    /// Imports presets from a JSON string.
    public func importFromJSON(_ jsonString: String, overwrite: Bool = false) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        let imported = try JSONDecoder().decode([MetronomePreset].self, from: data)

        lock.lock()
        defer { lock.unlock() }
        if overwrite {
            slots = imported
        } else {
            // Append non-duplicate IDs
            for preset in imported {
                if let existingIndex = slots.firstIndex(where: { $0.id == preset.id }) {
                    slots[existingIndex] = preset
                } else {
                    slots.append(preset)
                }
            }
        }
        savePersistedSlots()
    }

    /// Clears all presets.
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        slots.removeAll()
        selectedPresetId = nil
        savePersistedSlots()
    }
}
