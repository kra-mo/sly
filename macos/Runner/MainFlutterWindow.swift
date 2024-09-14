import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        self.minSize.width = 360
        self.minSize.height = 294

        self.styleMask.insert(StyleMask.fullSizeContentView)
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true

        self.center()
    }

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
