import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class TimerStore {
    var runningSession: Session?
    var elapsed: Int = 0           // seconds since start, minus paused time
    var activeClient: Client?
    var isPaused: Bool = false

    private var timer: Timer?
    private var modelContext: ModelContext?

    func configure(context: ModelContext) {
        self.modelContext = context
        // Resume any in-progress session surviving a crash/relaunch
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        if let running = try? context.fetch(descriptor).first {
            runningSession = running
            activeClient  = running.client
            isPaused      = running.isPaused
            recomputeElapsed()
            if !isPaused { startTick() }
        }
    }

    func start(client: Client, type: ProjectType) {
        guard runningSession == nil, let ctx = modelContext else { return }
        let session = Session(startedAt: .now, type: type, client: client)
        ctx.insert(session)
        try? ctx.save()   // crash-safe: persisted before UI updates
        runningSession = session
        activeClient   = client
        elapsed        = 0
        isPaused       = false
        startTick()
    }

    func end() {
        guard let session = runningSession, let ctx = modelContext else { return }
        resumeIfPaused(session: session)
        session.endedAt         = .now
        session.durationSeconds = elapsed
        try? ctx.save()
        stopTick()
        runningSession = nil
        elapsed        = 0
        isPaused       = false
    }

    func pause() {
        guard let session = runningSession, !isPaused else { return }
        session.currentPauseStart = Date.now.timeIntervalSince1970
        try? modelContext?.save()
        stopTick()
        isPaused = true
    }

    func resume() {
        guard let session = runningSession, isPaused else { return }
        resumeIfPaused(session: session)
        try? modelContext?.save()
        isPaused = false
        startTick()
    }

    // MARK: - Private

    private func resumeIfPaused(session: Session) {
        guard session.isPaused else { return }
        session.pausedSecondsAccumulated += Int(Date.now.timeIntervalSince1970 - session.currentPauseStart)
        session.currentPauseStart = 0
    }

    private func startTick() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recomputeElapsed()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTick() {
        timer?.invalidate()
        timer = nil
    }

    private func recomputeElapsed() {
        guard let session = runningSession else { return }
        let wall = Int(Date.now.timeIntervalSince(session.startedAt))
        elapsed  = max(0, wall - session.pausedSeconds)
    }
}
