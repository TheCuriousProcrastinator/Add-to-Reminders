import AppKit
import SwiftUI

struct HighlightingTextField: NSViewRepresentable {
    @Binding var text: String

    let recognizedRange: NSRange?
    let focusRequestID: Int
    let onSubmit: () -> Void
    let onEscape: () -> Void
    let onMoveSuggestion: (Int) -> Bool
    let onRejectRecognition: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false

        let textView = RecognitionTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.height]
        textView.font = .systemFont(ofSize: 18, weight: .medium)
        textView.textColor = .labelColor
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.maximumNumberOfLines = 1
        textView.textContainer?.lineBreakMode = .byClipping
        textView.textContainer?.containerSize = NSSize(
            width: .greatestFiniteMagnitude,
            height: scrollView.contentSize.height
        )
        textView.textContainer?.widthTracksTextView = false
        textView.onRecognizedClick = {
            context.coordinator.parent.onRejectRecognition()
        }

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? RecognitionTextView else { return }

        if textView.string != text {
            let selection = textView.selectedRange()
            textView.string = text
            let textLength = (text as NSString).length
            let location = min(selection.location, textLength)
            let length = min(selection.length, textLength - location)
            textView.setSelectedRange(NSRange(location: location, length: length))
        }

        textView.recognizedRange = recognizedRange
        context.coordinator.applyHighlight(to: textView)

        if context.coordinator.lastFocusRequestID != focusRequestID {
            context.coordinator.lastFocusRequestID = focusRequestID
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightingTextField
        var lastFocusRequestID = -1

        init(_ parent: HighlightingTextField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onEscape()
                return true
            case #selector(NSResponder.moveUp(_:)):
                return parent.onMoveSuggestion(-1)
            case #selector(NSResponder.moveDown(_:)):
                return parent.onMoveSuggestion(1)
            default:
                return false
            }
        }

        func applyHighlight(to textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: storage.length)

            storage.beginEditing()
            storage.setAttributes(
                [
                    .font: NSFont.systemFont(ofSize: 18, weight: .medium),
                    .foregroundColor: NSColor.labelColor
                ],
                range: fullRange
            )
            if let range = parent.recognizedRange, NSMaxRange(range) <= storage.length {
                storage.addAttributes(
                    [
                        .backgroundColor: NSColor.systemBlue.withAlphaComponent(0.16),
                        .foregroundColor: NSColor.systemBlue
                    ],
                    range: range
                )
            }
            storage.endEditing()
        }
    }
}

private final class RecognitionTextView: NSTextView {
    var recognizedRange: NSRange?
    var onRecognizedClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        let clickedRecognizedText = recognizedRange.map { range in
            characterIndex(at: event.locationInWindow).map { NSLocationInRange($0, range) } ?? false
        } ?? false

        super.mouseDown(with: event)

        if clickedRecognizedText {
            DispatchQueue.main.async { [weak self] in
                self?.onRecognizedClick?()
            }
        }
    }

    private func characterIndex(at windowPoint: NSPoint) -> Int? {
        guard let layoutManager, let textContainer else { return nil }
        let point = convert(windowPoint, from: nil)
        let containerPoint = NSPoint(
            x: point.x - textContainerOrigin.x,
            y: point.y - textContainerOrigin.y
        )
        let glyphIndex = layoutManager.glyphIndex(for: containerPoint, in: textContainer)
        guard glyphIndex < layoutManager.numberOfGlyphs else { return nil }
        let glyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 1),
            in: textContainer
        )
        guard glyphRect.insetBy(dx: -2, dy: -2).contains(containerPoint) else { return nil }
        return layoutManager.characterIndexForGlyph(at: glyphIndex)
    }
}
