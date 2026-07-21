import XCTest
import Defaults
@testable import Maccy

// swiftlint:disable type_body_length
class ClipboardTests: XCTestCase {
  let clipboard = Clipboard.shared
  let pasteboard = NSPasteboard.general
  let image = NSImage(named: "NSInfo")!
  let coloredString = NSAttributedString(string: "foo",
                                         attributes: [.foregroundColor: NSColor.red])

  let dynamicType = NSPasteboard.PasteboardType(rawValue: "dyn.ah62d4qmxhk4d425try1g44pdsm11g55gsu1e82xnqzv")
  let customType = NSPasteboard.PasteboardType(rawValue: "org.maccy.ConfidentialType")
  let fileURLType = NSPasteboard.PasteboardType.fileURL
  let htmlType = NSPasteboard.PasteboardType.html
  let jpegType = NSPasteboard.PasteboardType.jpeg
  let rtfType = NSPasteboard.PasteboardType.rtf
  let stringType = NSPasteboard.PasteboardType.string
  let tiffType = NSPasteboard.PasteboardType.tiff
  let transientType = NSPasteboard.PasteboardType.transient
  let unknownType = NSPasteboard.PasteboardType(rawValue: "com.apple.AnnotationKit.AnnotationItem")

  let savedEnabledTypes = Defaults[.enabledPasteboardTypes]
  let savedIgnoreEvents = Defaults[.ignoreEvents]
  let savedIgnoreAllAppsExceptListed = Defaults[.ignoreAllAppsExceptListed]
  let savedIgnoredApps = Defaults[.ignoredApps]
  let savedIgnoredPasteboardTypes = Defaults[.ignoredPasteboardTypes]

  override func setUp() {
    super.setUp()
    Defaults[.ignoreAllAppsExceptListed] = false
    Defaults[.ignoreEvents] = false
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.enabledPasteboardTypes] = savedEnabledTypes
    Defaults[.ignoreEvents] = savedIgnoreEvents
    Defaults[.ignoreOnlyNextEvent] = false
    Defaults[.ignoreAllAppsExceptListed] = savedIgnoreAllAppsExceptListed
    Defaults[.ignoredApps] = savedIgnoredApps
    Defaults[.ignoredPasteboardTypes] = savedIgnoredPasteboardTypes
    clipboard.clearHooks()
  }

  func testChangesListenerAndAddHooks() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreStringWithOnlySpaces() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(" ", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreStringWithOnlyNewlines() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("\n", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testDoesNotIgnoreRTF() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    let rtf = NSAttributedString(string: "foo").rtf(
      from: NSRange(0...2),
      documentAttributes: [:]
    )
    pasteboard.declareTypes([.rtf], owner: nil)
    pasteboard.setData(rtf, forType: .rtf)
    waitForExpectations(timeout: 2)
  }

  func testDoesNotIgnoreHTML() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.html], owner: nil)
    pasteboard.setString("foo", forType: .html)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreEventsIsEnabled() {
    Defaults[.ignoreEvents] = true

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foo", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreOnlyNextEventIsEnabled() {
    Defaults[.ignoreEvents] = true
    Defaults[.ignoreOnlyNextEvent] = true

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foo", forType: .string)
    waitForExpectations(timeout: 2)

    XCTAssertFalse(Defaults[.ignoreEvents])
    XCTAssertFalse(Defaults[.ignoreOnlyNextEvent])
  }

  func testIgnoreApplication() {
    Defaults[.ignoredApps] = ["com.apple.dt.Xcode", "com.apple.finder"] // Finder is on Bitrise

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreAllApplicationsExcept() {
    Defaults[.ignoreAllAppsExceptListed] = true
    Defaults[.ignoredApps] = ["com.apple.dt.Xcode", "com.apple.finder"] // Finder is on Bitrise

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreTransientTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string, transientType], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreCustomTypes() {
    Defaults[.ignoredPasteboardTypes] = [customType.rawValue]

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string, customType], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreCopiesWithUnknownTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([unknownType], owner: nil)
    pasteboard.setString(" ", forType: unknownType)
    waitForExpectations(timeout: 2)
  }

  @MainActor
  func testCopy() {
    let imageData = image.tiffRepresentation!
    let contents = [
      HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
      HistoryItemContent(type: tiffType.rawValue, value: imageData),
      HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!)
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.application = "com.foo.bar"
    clipboard.copy(item)
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.data(forType: .tiff), imageData)
    XCTAssertEqual(pasteboard.string(forType: .fileURL), "file://foo.bar")
    XCTAssertEqual(pasteboard.string(forType: .fromMaccy), "")
    XCTAssertEqual(pasteboard.string(forType: .source), "com.foo.bar")
  }

  @MainActor
  func testCopyString() {
    clipboard.copyInMaccy("foo")
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.string(forType: .source), NSPasteboard.PasteboardType.fromMaccy.rawValue)
  }

  @MainActor
  func testCopyWithoutFormatting() {
    let contents = [
      HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
      HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!),
      HistoryItemContent(type: rtfType.rawValue,
                         value: coloredString.rtf(from: NSRange(location: 0, length: coloredString.length),
                                                  documentAttributes: [:]))
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.application = "com.foo.bar"
    clipboard.copy(item, removeFormatting: true)
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.string(forType: .fromMaccy), "")
    XCTAssertEqual(pasteboard.string(forType: .source), "com.foo.bar")
    XCTAssertEqual(pasteboard.string(forType: .fileURL), "file://foo.bar")
    XCTAssertNil(pasteboard.data(forType: .rtf))
  }

  func testHandlesItemsWithoutData() {
    let hookExpectation = expectation(description: "Hook is called")
    pasteboard.clearContents()
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.fileURL, .string], owner: nil)
    // fileURL is left without data
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testMaterializesStandaloneImageFileURLFromCacheUsingDetectedType() throws {
    let jpegData = try XCTUnwrap(
      NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .jpeg, properties: [:])
    )
    let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("image.data")
    try jpegData.write(to: url)

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map(\.type), [self.jpegType.rawValue])
      XCTAssertEqual(item.imageData, jpegData)
      hookExpectation.fulfill()
    })

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])

    waitForExpectations(timeout: 2)
  }

  @MainActor
  func testMaterializesTemporaryImageFileURLWhenFilesAreDisabled() throws {
    Defaults[.enabledPasteboardTypes] = Set(StorageType.images.types)
    let pngData = try XCTUnwrap(
      NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .png, properties: [:])
    )
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("png")
    try pngData.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    var copiedItem: HistoryItem?
    clipboard.onNewCopy({ copiedItem = $0 })

    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])
    clipboard.checkForChangesInPasteboard()

    XCTAssertEqual(copiedItem?.contents.map(\.type), [NSPasteboard.PasteboardType.png.rawValue])
    XCTAssertEqual(copiedItem?.imageData, pngData)
  }

  @MainActor
  func testKeepsTemporaryNonImageFileURL() throws {
    Defaults[.enabledPasteboardTypes] = [.fileURL, .png, .tiff]
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("png")
    try Data("not an image".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    var copiedItem: HistoryItem?
    clipboard.onNewCopy({ copiedItem = $0 })

    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])
    clipboard.checkForChangesInPasteboard()

    XCTAssertEqual(copiedItem?.contents.map(\.type), [fileURLType.rawValue])
    XCTAssertEqual(copiedItem?.contents.first?.value, url.dataRepresentation)

    copiedItem = nil
    Defaults[.enabledPasteboardTypes] = Set(StorageType.images.types)
    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])
    clipboard.checkForChangesInPasteboard()

    XCTAssertNil(copiedItem)
  }

  @MainActor
  func testIgnoresTemporaryImageFileURLWithIgnoredTypes() throws {
    Defaults[.enabledPasteboardTypes] = [.fileURL, .png, .tiff]
    let pngData = try XCTUnwrap(
      NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .png, properties: [:])
    )
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("png")
    try pngData.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    var copiedItems = [HistoryItem]()
    clipboard.onNewCopy({ copiedItems.append($0) })

    for ignoredType in [NSPasteboard.PasteboardType.concealed, .transient] {
      let item = NSPasteboardItem()
      item.setData(url.dataRepresentation, forType: .fileURL)
      item.setData(Data(), forType: ignoredType)
      pasteboard.clearContents()
      pasteboard.writeObjects([item])
      clipboard.checkForChangesInPasteboard()
    }

    XCTAssertTrue(copiedItems.isEmpty)
  }

  func testDoesNotMaterializeStandalonePNGWhenImagesAreDisabled() throws {
    Defaults[.enabledPasteboardTypes] = [.fileURL]
    let pngData = try XCTUnwrap(
      NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .png, properties: [:])
    )
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("png")
    try pngData.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map(\.type), [self.fileURLType.rawValue])
      hookExpectation.fulfill()
    })

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])

    waitForExpectations(timeout: 2)
  }

  func testDoesNotMaterializeStandalonePNGOutsideTemporaryDirectories() throws {
    let pngData = try XCTUnwrap(
      NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .png, properties: [:])
    )
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("image.png")
    try pngData.write(to: url)

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map(\.type), [self.fileURLType.rawValue])
      hookExpectation.fulfill()
    })

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])

    waitForExpectations(timeout: 2)
  }

  func testMergesMultipleItems() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(
        Set(item.contents.map({ $0.type })),
        Set([self.tiffType.rawValue, self.stringType.rawValue])
      )
      hookExpectation.fulfill()
    })

    let item1 = NSPasteboardItem()
    item1.setString("foo", forType: .string)
    let item2 = NSPasteboardItem()
    item2.setData(image.tiffRepresentation!, forType: .tiff)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item1, item2])

    waitForExpectations(timeout: 2)
  }

  func testRemovesDisabledTypes() {
    Defaults[.enabledPasteboardTypes] = [.fileURL]

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map({ $0.type }), [self.fileURLType.rawValue])
      hookExpectation.fulfill()
    })

    let item = NSPasteboardItem()
    item.setString("foo", forType: .string)
    item.setData(image.tiffRepresentation!, forType: .tiff)
    item.setData("file://foo.bar".data(using: .utf8)!, forType: .fileURL)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item])

    waitForExpectations(timeout: 2)
  }

  func testRemovesDynamicTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map({ $0.type }), [self.stringType.rawValue])
      hookExpectation.fulfill()
    })

    let item = NSPasteboardItem()
    item.setString("foo", forType: .string)
    item.setData("".data(using: .utf8)!, forType: dynamicType)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item])

    waitForExpectations(timeout: 2)
  }
}
// swiftlint:enable type_body_length
