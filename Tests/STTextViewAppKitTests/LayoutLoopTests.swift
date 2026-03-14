#if os(macOS)
    import AppKit
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    final class LayoutLoopTests: XCTestCase {

        func testSelectAllDeleteInScrollViewDocumentView() {
            let harness = ScrollViewHarness()
            let textView = harness.textView

            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.text = """
            alpha
            beta
            gamma
            delta
            epsilon
            """

            harness.flushLayout()

            textView.selectAll(nil)
            textView.deleteBackward(nil)

            harness.flushLayout()

            XCTAssertEqual(textView.text, "")
            XCTAssertEqual(textView.selectedRange(), NSRange(location: 0, length: 0))
            XCTAssertGreaterThan(textView.frame.height, 0)
        }

        func testSelectAllDeleteInScrollViewDocumentViewAfterScrolling() {
            let harness = ScrollViewHarness()
            let textView = harness.textView

            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.text = Array(repeating: "alpha beta gamma delta epsilon zeta eta theta iota kappa", count: 200).joined(separator: "\n")

            harness.flushLayout()
            harness.scrollToBottom()

            textView.selectAll(nil)
            textView.deleteBackward(nil)

            harness.flushLayout()

            XCTAssertEqual(textView.text, "")
            XCTAssertEqual(textView.selectedRange(), NSRange(location: 0, length: 0))
            XCTAssertGreaterThan(textView.frame.height, 0)
        }

        func testUsageBoundsInvalidatesIntrinsicContentSize() {
            let harness = TrackingScrollViewHarness()
            let textView = harness.trackingTextView

            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.text = "alpha\nbeta\ngamma\ndelta\nepsilon"

            harness.flushLayout()
            textView.invalidatedIntrinsicContentSizeCount = 0

            textView.selectAll(nil)
            textView.deleteBackward(nil)

            harness.flushLayout()

            XCTAssertGreaterThan(textView.invalidatedIntrinsicContentSizeCount, 0)
        }
    }

    @MainActor
    private protocol LayoutHarness {
        var window: NSWindow { get }
        var textView: STTextView { get }
        func flushLayout()
        func scrollToBottom()
    }

    @MainActor
    private extension LayoutHarness {
        func flushLayout() {
            window.contentView?.layoutSubtreeIfNeeded()
            textView.layoutSubtreeIfNeeded()

            RunLoop.current.run(until: Date().addingTimeInterval(0.01))

            window.contentView?.layoutSubtreeIfNeeded()
            textView.layoutSubtreeIfNeeded()
        }

        func scrollToBottom() {}
    }

    @MainActor
    private final class ScrollViewHarness: LayoutHarness {
        let window: NSWindow
        let scrollView: NSScrollView
        let textView: STTextView

        convenience init() {
            let scrollView = STTextView.scrollableTextView()
            self.init(scrollView: scrollView, textView: scrollView.documentView as! STTextView)
        }

        init(scrollView: NSScrollView, textView: STTextView) {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            self.scrollView = scrollView
            self.textView = textView

            guard let contentView = window.contentView else {
                fatalError("Missing window content view")
            }

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(scrollView)
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            window.makeKeyAndOrderFront(nil)
        }

        func scrollToBottom() {
            let documentHeight = textView.frame.height
            let visibleHeight = scrollView.contentView.bounds.height
            guard documentHeight > visibleHeight else {
                return
            }

            scrollView.contentView.scroll(to: CGPoint(x: 0, y: documentHeight - visibleHeight))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            flushLayout()
        }
    }

    @MainActor
    private final class TrackingScrollViewHarness: LayoutHarness {
        let window: NSWindow
        let scrollView: NSScrollView
        let trackingTextView: TrackingTextView

        var textView: STTextView {
            trackingTextView
        }

        init() {
            let scrollView = TrackingTextView.scrollableTextView()
            self.window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            self.scrollView = scrollView
            self.trackingTextView = scrollView.documentView as! TrackingTextView

            guard let contentView = window.contentView else {
                fatalError("Missing window content view")
            }

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(scrollView)
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            window.makeKeyAndOrderFront(nil)
        }

        func scrollToBottom() {}
    }

    @MainActor
    private final class TrackingTextView: STTextView {
        var invalidatedIntrinsicContentSizeCount = 0

        override func invalidateIntrinsicContentSize() {
            invalidatedIntrinsicContentSizeCount += 1
            super.invalidateIntrinsicContentSize()
        }
    }
#endif
