// «Share to RedGiant» on iOS (G40.10): PREPARED, NOT ACTIVE. Not part of Runner.xcodeproj yet,
// so nothing here is built. The receive_sharing_intent plugin's controller takes the text, links,
// photos and files shared and opens RGCompanion, whose Share screen chooses the Chat or an
// agent, adds a note and sends (the same as Android's ACTION_SEND).
//
// To switch it on (Xcode, with the account that publishes the app):
//   1. File > New > Target > Share Extension, named "ShareExtension", bundle id
//      com.redgiant.companion.ShareExtension, the same deployment target as Runner; replace its
//      files with this folder's ShareViewController.swift and Info.plist.
//   2. Add the `receive-sharing-intent` library to the extension (Frameworks and Libraries).
//   3. App Groups in BOTH Runner and ShareExtension: group.com.redgiant.companion, and the
//      user-defined build setting CUSTOM_GROUP_ID = group.com.redgiant.companion in both.
//   4. Runner's Info.plist: AppGroupId = $(CUSTOM_GROUP_ID) and the URL scheme
//      ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER) (CFBundleURLTypes), as the plugin's README says.
//   5. Build Phases of Runner: «Embed Foundation Extensions» above «Thin Binary».
import receive_sharing_intent

class ShareViewController: RSIShareViewController {
  // Straight into the app: the note and the choice of agent are made there.
  override func shouldAutoRedirect() -> Bool { true }
}
