import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // A computer's window (G40.17): wide enough for the control room, centred.
    var windowFrame = self.frame
    if let screen = NSScreen.main?.visibleFrame {
      let width = min(1280, screen.width)
      let height = min(820, screen.height)
      windowFrame = NSRect(
        x: screen.midX - width / 2, y: screen.midY - height / 2, width: width, height: height)
    }
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 420, height: 560)
    // The window says the product's name (plan 3.9.0); Applications shows «Rasgeth App».
    self.title = "Rasgeth"


    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
