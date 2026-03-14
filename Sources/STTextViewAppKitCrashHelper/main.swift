#if os(macOS)
import AppKit
import SwiftUI
import STTextViewAppKit

@MainActor
private final class ReproController: ObservableObject {
    weak var textView: STTextView?
    private var didScheduleDelete = false

    func scheduleDeleteIfNeeded() {
        guard !didScheduleDelete, let textView, textView.window != nil else {
            return
        }

        didScheduleDelete = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            textView.selectAll(nil)
            textView.deleteBackward(nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(EXIT_SUCCESS)
            }
        }
    }
}

@MainActor
private struct SplitViewTextEditor: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var controller: ReproController

    func makeNSView(context: Context) -> NSScrollView {
        let textView = STTextView()
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        controller.textView = textView

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? STTextView else {
            return
        }

        let currentText = textView.text ?? ""
        if currentText != text {
            textView.text = text
        }

        controller.scheduleDeleteIfNeeded()
    }
}

@MainActor
private struct CrashReproView: View {
    @State private var text = ""
    @StateObject private var controller = ReproController()

    private let sampleText = Array(repeating: "alpha beta gamma delta epsilon", count: 200).joined(separator: "\n")

    var body: some View {
        HSplitView {
            Color.red.frame(minWidth: 160, idealWidth: 180, maxWidth: 400)
            SplitViewTextEditor(text: $text, controller: controller)
                .frame(minWidth: 400)
            Color.blue.frame(minWidth: 200, idealWidth: 220, maxWidth: 500)
        }
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            if text.isEmpty {
                text = sampleText
            }
        }
    }
}

@main
struct STTextViewAppKitCrashHelperApp: App {
    var body: some Scene {
        WindowGroup {
            CrashReproView()
                .frame(width: 1200, height: 800)
        }
    }
}
#endif
