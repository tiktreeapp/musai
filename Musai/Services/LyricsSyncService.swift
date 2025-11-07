//
//  LyricsSyncService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import Combine

class LyricsSyncService: ObservableObject {
    @Published var currentLyricIndex: Int = 0
    @Published var isPlaying: Bool = false
    
    private var lyrics: [LyricLine] = []
    private var timer: Timer?
    private var currentTime: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    
    func setLyrics(_ lyrics: [LyricLine]) {
        self.lyrics = lyrics
        self.currentLyricIndex = 0
    }
    
    func startSync(currentTime: TimeInterval) {
        self.currentTime = currentTime
        self.isPlaying = true
        
        stopSync()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentLyric()
        }
    }
    
    func pauseSync() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func stopSync() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentLyricIndex = 0
    }
    
    func updateTime(_ time: TimeInterval) {
        currentTime = time
        if isPlaying {
            updateCurrentLyric()
        }
    }
    
    private func updateCurrentLyric() {
        guard !lyrics.isEmpty else { return }
        
        var newIndex = 0
        
        for (index, lyric) in lyrics.enumerated() {
            if currentTime >= lyric.time {
                newIndex = index
            } else {
                break
            }
        }
        
        if newIndex != currentLyricIndex {
            currentLyricIndex = newIndex
        }
    }
    
    deinit {
        stopSync()
    }
}

// MARK: - Lyrics Parser
extension LyricsSyncService {
    
    static func parseLyrics(_ lyricsText: String) -> [LyricLine] {
        let lines = lyricsText.components(separatedBy: .newlines)
        var parsedLines: [LyricLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                // Parse timestamped lyrics format: [00:12.34]Lyrics here
                if let lyricLine = parseTimestampedLine(trimmedLine) {
                    parsedLines.append(lyricLine)
                } else {
                    // Estimate timestamp based on line position (2 seconds per line as default)
                    let timestamp = TimeInterval(index * 2)
                    parsedLines.append(LyricLine(time: timestamp, text: trimmedLine))
                }
            }
        }
        
        return parsedLines
    }
    
    private static func parseTimestampedLine(_ line: String) -> LyricLine? {
        // Pattern: [mm:ss.xx]Lyrics here
        let pattern = #"^\[(\d{2}):(\d{2})\.(\d{2})\](.*)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let minutesRange = Range(match.range(at: 1), in: line)!
        let secondsRange = Range(match.range(at: 2), in: line)!
        let centisecondsRange = Range(match.range(at: 3), in: line)!
        let lyricsRange = Range(match.range(at: 4), in: line)!
        
        let minutes = Int(line[minutesRange]) ?? 0
        let seconds = Int(line[secondsRange]) ?? 0
        let centiseconds = Int(line[centisecondsRange]) ?? 0
        let lyrics = String(line[lyricsRange]).trimmingCharacters(in: .whitespaces)
        
        let timestamp = TimeInterval(minutes * 60 + seconds) + TimeInterval(centiseconds) / 100.0
        
        return LyricLine(time: timestamp, text: lyrics)
    }
    
    static func formatLyricsWithTimestamps(_ lyrics: [String]) -> String {
        var formattedLyrics = ""
        
        for (index, line) in lyrics.enumerated() {
            let time = TimeInterval(index * 2)
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
            
            formattedLyrics += String(format: "[%02d:%02d.%02d]%@", minutes, seconds, centiseconds, line)
            formattedLyrics += "\n"
        }
        
        return formattedLyrics
    }
}

// MARK: - Lyrics Storage
extension LyricsSyncService {
    
    func saveLyricsToFile(_ lyrics: [LyricLine], filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(filename).lrc")
        
        var content = ""
        for lyric in lyrics {
            let minutes = Int(lyric.time) / 60
            let seconds = Int(lyric.time) % 60
            let centiseconds = Int((lyric.time.truncatingRemainder(dividingBy: 1)) * 100)
            content += String(format: "[%02d:%02d.%02d]%@", minutes, seconds, centiseconds, lyric.text)
            content += "\n"
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving lyrics: \(error)")
        }
    }
    
    func loadLyricsFromFile(filename: String) -> [LyricLine]? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(filename).lrc")
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return Self.parseLyrics(content)
        } catch {
            print("Error loading lyrics: \(error)")
            return nil
        }
    }
}