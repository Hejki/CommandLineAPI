/*
 *  CommandLineAPI
 *
 *  Copyright (c) 2019 Hejki. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the  Software), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

/**
 A `Path` represents an absolute path on a filesystem.

 All functions on `Path` are chainable to facilitate doing sequences of file operations.

 - Note: A `Path` does not necessarily represent an actual filesystem entry.
 */
public struct Path {

    /// The URL representation of the underlaying filesystem path.
    public let url: URL

    /// The normalized string representation of the underlying filesystem path.
    public var path: String {
        url.path
    }

    /// Init path wit exact path string and skip all validations.
    fileprivate init(exactPath: String) {
        self.url = URL(fileURLWithPath: exactPath)
    }

    /**
     Creates a new absolute, standardized path from the provided file-scheme URL.

     - Parameter url: The path URL.
     - Throws: `Path.Error.invalidURLScheme` if URL scheme is not `file`.
     */
    public init(url: URL) throws {
        guard url.scheme == "file" else {
            throw Error.invalidURLScheme(url.scheme ?? "nil")
        }
        try self.init(url.path)
    }

    /**
     Creates a new absolute, standardized path.

     - Parameter path: The string represented an absolute path
     - Throws: `Path.Error.cannotResolvePath` if *path* cannot be resolved.
     - Note:
        * Resolves any `..` or `.` components in *path*.
        * Resolves initial `~/` with path to current user home directory.
        * Resolves initial `~user/` with path to specified user home directory.
        * Does not resolve any symlinks.
        * If provided *path* is relative (not prefixed with `/`) then the resolved path is relative to the current working directory.
        * On macOS, removes an initial component of "/private/var/automount", "/var/automount", or "/private" from the path,
          if the result still indicates an existing file or directory.
     */
    public init<S: StringProtocol>(_ path: S) throws {
        var pathComponents = path.split(separator: "/")

        switch path.first {
        case "/":
            #if os(macOS)
            func ifExists(withPrefix prefix: String, removeFirst n: Int) {
                if path.hasPrefix(prefix), FileManager.default.fileExists(atPath: String(path)) {
                    pathComponents.removeFirst(n)
                }
            }

            ifExists(withPrefix: "/private/var/automount", removeFirst: 3)
            ifExists(withPrefix: "/var/automount", removeFirst: 2)
            ifExists(withPrefix: "/private", removeFirst: 1)
            #endif
            self.url = Path.with(prefix: "/", pathComponents: pathComponents)

        case "~":
            if path == "~" {
                self.url = Path.home.url
                return
            }

            let tilded: String
            if path.hasPrefix("~/") {
                tilded = Path.home.path
            } else {
                let username = String(pathComponents[0].dropFirst())

                #if os(macOS) || os(Linux)
                if #available(OSX 10.12, *) {
                    guard let url = FileManager.default.homeDirectory(forUser: username) else {
                        throw Error.cannotResolvePath("~\(username)")
                    }
                    tilded = url.path
                } else {
                    guard let homeDir = NSHomeDirectoryForUser(username) else {
                        throw Error.cannotResolvePath("~\(username)")
                    }
                    tilded = homeDir
                }
                #else
                throw Error.cannotResolvePath("~\(username)")
                #endif
            }

            pathComponents.removeFirst()
            self.url = Path.with(prefix: tilded, pathComponents: pathComponents)
        default:
            self.url = Path.with(prefix: Path.current.path, pathComponents: pathComponents)
        }
    }

    /**
     Creates a new absolute, standardized path which is constructed from *path* which is relative to *parent* path.

     - Parameters:
        - path: A string which represends the relative part of the path.
        - parent: The parent of the target path.
     */
    @inlinable
    public init<S: StringProtocol>(_ path: S, relativeTo parent: Path) {
        self.url = parent.appending(path).url
    }

    private static func with<S>(prefix: String, pathComponents: S) -> URL where S: Sequence, S.Element: StringProtocol {

        var path = prefix
        for component in pathComponents {
            switch component {
            case "..":
                let start = path.indices.startIndex
                let index = path.lastIndex(of: "/")!
                if start == index {
                    path = "/"
                } else {
                    path = String(path[start ..< index])
                }
            case ".":
                break
            default:
                if path == "/" {
                    path = "/\(component)"
                } else {
                    path = "\(path)/\(component)"
                }
            }
        }

        return URL(fileURLWithPath: path)
    }
}

// MARK: - Common Paths
public extension Path {

    /// The `Path` to the root directory.
    static let root = Path(exactPath: "/")

    /// The `Path` to the current working directory.
    static var current: Path {
        return try! .init(FileManager.default.currentDirectoryPath)
    }

    /// The current user's home
    static var home: Path {
        let path: String

        #if os(macOS)
        if #available(OSX 10.12, *) {
            path = FileManager.default.homeDirectoryForCurrentUser.path
        } else {
            path = NSHomeDirectory()
        }
        #else
        path = NSHomeDirectory()
        #endif

        return .init(exactPath: path)
    }

    /// The system's temporary directory.
    static var temporary: Path {
        if #available(OSX 10.12, *) {
            return try! .init(url: FileManager.default.temporaryDirectory)
        }
        return try! .init(NSTemporaryDirectory())
    }
}

// MARK: - Filesystem Representation
private let specialExtensions = [
    ".tar.gz", ".tar.bz", ".tar.bz2", ".tar.xz",
]

public extension Path {

    /// The parent directory for this path.
    /// - Note: Always returns a valid path, `Path.root.parent` is `Path.root`.
    var parent: Path {
        if path == "/" {
            return self
        }

        return try! Path(url: url.deletingLastPathComponent())
    }

    /**
     A sequence containing all of this folder's filesystem items. Initially
     non-recursive and skip hidden items, use `recursive` or `includingHidden`
     on the returned sequence to change that.
     */
    var children: ChildSequence {
        ChildSequence(self)
    }

    /// The path components, or an empty array for root path.
    var pathComponents: [String] {
        return path.split(separator: "/").map(String.init)
    }

    /// The basename for this filesystem item including `extension`.
    @inlinable
    var basename: String {
        return url.lastPathComponent
    }

    /**
     Returns the filename extension of this path.

     - Note:
        * If there is no extension returns empty string.
        * If the filename ends with any number of ".", returns empty string.
     */
    var `extension`: String {
        let basename = self.basename

        for ext in specialExtensions where basename.hasSuffix(ext) {
            return String(ext.dropFirst())
        }

        if let dot = basename.lastIndex(of: ".") {
            let index = basename.index(after: dot)
            return String(basename[index...])
        }
        return ""
    }

    /// The basename for this filesystem item without file `extension`.
    var basenameWithoutExtension: String {
        let basename = self.basename
        let ext = self.extension

        if !ext.isEmpty {
            return String(basename.dropLast(ext.count + 1))
        }
        return basename
    }

    /**
     Returns a string representing the relative path to `base`. If `base` is not
     a logical prefix for `self` your result will be prefixed some number of `../` components.

     - Parameter base:  The base to which we calculate the relative path.
     - Returns: The relative path to `base`.
     */
    func path(relativeTo base: Path) -> String {
        let pathComponents = self.pathComponents
        let baseComponents = base.pathComponents

        if pathComponents.starts(with: baseComponents) {
            return pathComponents.dropFirst(baseComponents.count)
                .joined(separator: "/")
        }

        var pathSlice = ArraySlice(pathComponents)
        var baseSlice = ArraySlice(baseComponents)

        while pathSlice.prefix(1) == baseSlice.prefix(1) {
            pathSlice = pathSlice.dropFirst()
            baseSlice = baseSlice.dropFirst()
        }

        var relativeComponents = Array(repeating: "..", count: baseSlice.count)

        relativeComponents.append(contentsOf: pathSlice)
        return relativeComponents.joined(separator: "/")
    }

    /**
     Returns a new path made by appending a given path string.

     - Note: `..` and `.` components are interpreted.
     - Parameter path: The path to append to this path
     - Returns: A new path made by appending *path* to the receiver.
     */
    func appending<S: StringProtocol>(_ path: S?) -> Path {
        guard let path = path else {
            return self
        }

        let components = path.split(separator: "/")
        return try! .init(url: Path.with(prefix: self.path, pathComponents: components))
    }

    /**
     Create a new path by appending the *append* string to the specified *path*.

     - Note: `..` and `.` components are interpreted.
     - Parameters:
        - path: The base path for the new one.
        - append: The string path to join with specified *path*.
     - Returns: A new joined path.
     - SeeAlso: `appending(_:)`
     */
    static func + <S: StringProtocol>(path: Path, append: S?) -> Path {
        return path.appending(append)
    }
}

/**
 Joins a *left* path with the *right* path string and stores the result in the left-hand-side variable.

 - Parameters:
    - left: The base path for the new one.
    - right: The string path to join with specified *left* path.
 */
@inlinable
public func += <S: StringProtocol>(left: inout Path, right: S?) {
    left = left.appending(right)
}

// MARK: - Filesystem Attributes
public extension Path {

    /**
     A type of a filesystem entry at this path. An `.unknown` value is returned
     if the entry doesn't exist or the type cannot be determined.
     */
    var type: EntryType {
        guard let stat = getStat() else {
            return .unknown
        }

        if stat.st_mode & S_IFMT == S_IFREG {
            return .file
        } else if stat.st_mode & S_IFMT == S_IFDIR {
            return .directory
        } else if stat.st_mode & S_IFMT == S_IFLNK {
            return .symlink
        } else if stat.st_mode & S_IFMT == S_IFIFO {
            return .pipe
        }
        return .unknown
    }

    /**
     An attributes of a filesystem entry, or `nil` if entry not exist.
     */
    var attributes: Attributes? {
        do {
            return try Attributes(path: self)
        } catch {
            return nil
        }
    }

    private func getStat() -> stat? {
        var buf = stat()
        guard lstat(path, &buf) == 0 else {
            return nil
        }

        return buf
    }
}

// MARK: - Input/Output Operations
public extension Path {

    /**
     Writes the *text* to file on this path.

     - Parameters:
        - text: The string content to write.
        - append: Appends the string to the end of file.
        - targetEncoding: The encoding in which the string should be interpreted.
     - Returns: `Self` to allow chaining.
     */
    @discardableResult
    func write(text: String, append: Bool = false, encoding targetEncoding: String.Encoding = .utf8) throws -> Path {
        return try text.write(to: self, append: append, encoding: targetEncoding)
    }

    /**
     Writes the *data* to file on this path.

     - Parameters:
        - data: The data content to write.
        - append: Appends the data to the end of file.
     - Returns: `Self` to allow chaining.
     */
    @discardableResult
    func write(data: Data, append: Bool = false) throws -> Path {
        return try data.write(to: self, append: append)
    }
}

public extension String {

    /**
     Creates a string with the content of the file at the given *path*.

     - Parameter path: The location of file.
     */
    @inlinable
    init(contentsOf path: Path) throws {
        try self.init(contentsOf: path.url)
    }

    /**
     Writes this string to file on *path*.

     - Parameters:
        - path: The location to which to write this string.
        - append: Appends the string to the end of file.
        - useAuxiliaryFile: If `true`, the string is written to a backup location,
          and then the backup location is renamed to the name specified by *path*;
          otherwise, the data is written directly to *path*.
        - targetEncoding: The encoding in which the string should be interpreted.
     - Returns: The *path* to allow chaining.
     */
    @discardableResult
    func write(to path: Path,
               append: Bool = false,
               atomically useAuxiliaryFile: Bool = false,
               encoding targetEncoding: String.Encoding = .utf8) throws -> Path {

        if path.exist {
            if let data = self.data(using: targetEncoding) {
                try data.write(to: path, append: append, atomically: useAuxiliaryFile)
            }
        } else {
            try write(to: path.url, atomically: useAuxiliaryFile, encoding: targetEncoding)
        }
        return path
    }
}

public extension Data {

    /**
     Creates a data with the content of the file at the given *path*.

     - Parameter path: The location of file .
     */
    @inlinable
    init(contentsOf path: Path) throws {
        try self.init(contentsOf: path.url)
    }

    /**
     Writes this data to file on *path*.

     - Parameters:
        - path: The location to which to write this data.
        - append: Appends the data to the end of file.
        - useAuxiliaryFile: If `true`, the string is written to a backup location,
          and then the backup location is renamed to the name specified by *path*;
          otherwise, the data is written directly to *path*.
     - Returns: The *path* to allow chaining.
     */
    @discardableResult
    func write(to path: Path, append: Bool = false, atomically useAuxiliaryFile: Bool = false) throws -> Path {
        if path.exist {
            let fileHandle = try FileHandle(forWritingTo: path.url)
            defer {
                fileHandle.closeFile()
            }

            if append {
                fileHandle.seekToEndOfFile()
            } else {
                #if os(macOS)
                if #available(OSX 10.15, *) {
                    try fileHandle.truncate(atOffset: 0)
                } else {
                    fileHandle.truncateFile(atOffset: 0)
                }
                #else
                try fileHandle.truncate(toOffset: 0)
                #endif
            }
            fileHandle.write(self)
        } else {
            try write(to: path.url, options: useAuxiliaryFile ? [.atomic] : [])
        }
        return path
    }
}

// MARK: - File Management
public extension Path {

    /**
     Returns a Boolean value that indicates whether this path represents an actual filesystem entry.
     A `false` was returned if the entry does not exist or its existence could not be determined.
     */
    var exist: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }

    /**
     Copies this filesystem item to the another *destination*. If the *destination* path is directory
     then the current item will be placed to that directory (`destination/self.basename`).

     - Parameters:
        - destination: The new location for item on this path.
        - overwrite: If `true` overwrites file on *destination* location.
     - Returns: A `Path` to copied item location.
     - Throws: An error if file cannot be copied.
     */
    @discardableResult
    func copy(to destination: Path, overwrite: Bool = false) throws -> Path {
        let dst = try resolveDestination(destination, overwrite)

        try FileManager.default.copyItem(at: self.url, to: dst.url)
        return dst
    }

    /**
     Moves this filesystem item to the another *destination*. If the *destination* path is directory
     then the current item will be moved into that directory (`destination/self.basename`).

     - Parameters:
        - destination: The new location for this item.
        - overwrite: If `true` overwrites file on *destination* location.
     - Returns: A `Path` to moved item.
     - Throws: An error if file cannot be moved.
     */
    @discardableResult
    func move(to destination: Path, overwrite: Bool = false) throws -> Path {
        let dst = try resolveDestination(destination, overwrite)

        try FileManager.default.moveItem(at: url, to: dst.url)
        return dst
    }

    private func resolveDestination(_ destination: Path, _ overwrite: Bool) throws -> Path {

        let target: Path
        if destination.type == .directory {
            target = destination.appending(basename)
        } else {
            target = destination
        }

        if target.exist && overwrite && target.type != .directory {
            try target.delete()
        }
        return target
    }

    /**
     Creates an empty file at this path or if the file exists, updates its modification time.

     - Note: If *name* is path and directories in this path not exists then throws error.
     - Parameter name: The name of the new file. If *name* not provided or `nil` then file will be created
        at `self.path`. If *name* is specified then new file path will be `self.path.appending(name)`.
     - Returns: A `Path` to the new file.
     - Throws: An error if file cannot be created or modification time cannot be change.
     */
    @discardableResult
    func touch(_ name: String? = nil) throws -> Path {
        let destinationPath = self.appending(name)

        if !destinationPath.exist {
            guard FileManager.default.createFile(atPath: destinationPath.path, contents: nil) else {
                throw CocoaError.error(.fileWriteUnknown)
            }
        } else {
            try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: destinationPath.path)
        }
        return destinationPath
    }

    /**
     Creates a directory at this path or at new appended path if the *name* was supplied.

     - Parameter name: The name of the new directory or `nil` if you want use this path.
        This *name* can be used to create intermediary directories.
     - Returns: A `Path` to the new directory.
     - Throws: An error if directory cannot be created.
     */
    @discardableResult
    func createDirectory(_ name: String? = nil) throws -> Path {
        let directoryPath: Path
        if let name = name {
            directoryPath = self.appending(name)
        } else {
            directoryPath = self
        }

        try FileManager.default.createDirectory(at: directoryPath.url, withIntermediateDirectories: true)
        return directoryPath
    }

    /**
     Deletes the path, recursively if a directory.

     If path doesn't exist do nothing. If entry is a symlink, deletes the symlink.

     - Parameter useTrash: Move the path to the trash insted of delete.
     */
    func delete(useTrash: Bool = false) throws {
        if useTrash {
            #if os(macOS)
            try FileManager.default.trashItem(at: self.url, resultingItemURL: nil)
            #else
            try FileManager.default.removeItem(at: self.url)
            #endif
        } else {
            try FileManager.default.removeItem(at: self.url)
        }
    }

    /**
     Renames the filesystem item at this path.

     - Parameter name: The new name of this item.
     - Returns: A `Path` to the renamed item.
     - Throws: `Error.invalidArgumentValue` if new *name* contain directory separator.
     */
    @discardableResult
    func rename(to name: String) throws -> Path {
        guard !name.contains("/") else {
            throw Error.invalidArgumentValue(
                arg: "name",
                "New path name cannot contains directory separator, use `Path.move(to:)`."
            )
        }

        let newPath = parent.appending(name)

        try FileManager.default.moveItem(at: url, to: newPath.url)
        return newPath
    }
}

// MARK: - String Convertible and Expressible
extension Path: CustomStringConvertible {

    /// Returns `Path.string`
    @inlinable
    public var description: String {
        return path
    }
}

extension Path: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose` functions.
     */
    @inlinable
    public init?(stringArgument: String) {
        try? self.init(stringArgument)
    }
}

// MARK: - Equatable, Hashable, etc.
extension Path: Equatable, Hashable, Comparable {
    @inlinable
    public static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    public static func < (lhs: Path, rhs: Path) -> Bool {
        lhs.path < rhs.path
    }
}

extension Path: Codable {

    /**
     Creates a new instance of path by decoding from the given decoder.

     - Parameter decoder: The decoder to read data from.
     */
    public init(from decoder: Decoder) throws {
        try self.init(decoder.singleValueContainer().decode(String.self))
    }

    /**
     Encodes this path into the given encoder.

     - Parameter encoder: The encoder to write data to.
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.path)
    }
}

// MARK: - Bundle Extension
public extension Bundle {

    /// The `Path` of the receiver's bundle directory.
    var path: Path {
        try! Path(bundlePath)
    }

    /**
     Returns the path for the resource identified by the specified name and file extension.

     - Parameters:
        - name: The name of the resource file
        - extension: The filename extension of the file to locate.
     - Returns: The path for the resource file, or `nil` if the file could not be located.
     - SeeAlso: [Bundle.path(forResource:withExtension:)](https://developer.apple.com/documentation/foundation/bundle/1411540-url)
     */
    func path(forResource name: String?, withExtension extension: String?) -> Path? {
        if let url = self.url(forResource: name, withExtension: `extension`) {
            return try? Path(url: url)
        }
        return nil
    }
}

// MARK: - Supporting Objects
public extension Path {

    /**
     Filesystem entry attributes representation.
     */
    struct Attributes {
        private let path: String
        private var fileAttributes: [FileAttributeKey: Any]

        /**
         The filesystem item's creation date.
         */
        public var creationDate: Date {
            get { fileAttributes[.creationDate] as! Date }
            set { setAttribute(.creationDate, to: newValue) }
        }

        #if os(macOS)
        /**
         This value indicates wheter the filesystem item's extension is hidden.
         */
        public var extensionHidden: Bool {
            get { fileAttributes[.extensionHidden] as! Bool }
            set { setAttribute(.extensionHidden, to: newValue) }
        }
        #endif

        /**
         The group name of the filesystem item's owner.
         */
        public var groupName: String {
            get { fileAttributes[.groupOwnerAccountName] as! String }
            set { setAttribute(.groupOwnerAccountName, to: newValue) }
        }

        /**
         The filesystem item's last modified date.
         */
        public var modificationDate: Date {
            get { fileAttributes[.modificationDate] as! Date }
            set { setAttribute(.modificationDate, to: newValue) }
        }

        /**
         The user name of the filesystem item's owner.
         */
        public var userName: String {
            get { fileAttributes[.ownerAccountName] as! String }
            set { setAttribute(.ownerAccountName, to: newValue) }
        }

        /**
         The filesystem item's permissions.
         */
        public var permissions: Permissions {
            get { Permissions(rawValue: fileAttributes[.posixPermissions] as! Int) }
            set { setAttribute(.posixPermissions, to: newValue.rawValue) }
        }

        /**
         The filesystem item's size in bytes.
         */
        public var size: Int {
            fileAttributes[.size] as! Int
        }

        fileprivate init(path: Path) throws {
            self.path = path.path
            self.fileAttributes = try FileManager.default.attributesOfItem(atPath: path.path)
        }

        /**
         Reload attribute values from underlying path.

         - Throws: An error if attributes cannot be resolved.
         */
        public mutating func reload() throws {
            self.fileAttributes = try FileManager.default.attributesOfItem(atPath: path)
        }

        private mutating func setAttribute(_ attribute: FileAttributeKey, to value: Any) {
            do {
                try FileManager.default.setAttributes([attribute: value], ofItemAtPath: path)
                fileAttributes[attribute] = value
            } catch {
                CLI.println(error: "Failed to set attribute \(attribute) to value \(value). Error \(error)")
            }
        }
    }

    /**
     A sequence of child locations contained within a given folder.
     You obtain an instance of this type by accessing `children` on `Path` instance.
     */
    struct ChildSequence: Sequence {
        private let path: Path
        private var enumeratorOptions: FileManager.DirectoryEnumerationOptions

        fileprivate init(_ path: Path) {
            self.path = path
            self.enumeratorOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]
        }

        /**
         Return a new instance of this sequence that'll traverse the directory's content recursively.
         */
        public var recursive: ChildSequence {
            var sequence = self

            sequence.enumeratorOptions.remove(.skipsSubdirectoryDescendants)
            sequence.enumeratorOptions.remove(.skipsPackageDescendants)
            return sequence
        }

        /**
         Return a new instance of this sequence that'll include all hidden filesystem items
         when traversing the directory's contents.
         */
        public var includingHidden: ChildSequence {
            var sequence = self

            sequence.enumeratorOptions.remove(.skipsHiddenFiles)
            return sequence
        }

        /**
         Checks if this sequence is empty.
         */
        public var isEmpty: Bool {
            first(where: { _ in true }) == nil
        }

        /**
         Count the number of items countained within this sequence.
         */
        public var count: Int {
            reduce(0) { count, _ in count + 1 }
        }

        public func makeIterator() -> ChildSequenceIterator {
            ChildSequenceIterator(FileManager.default.enumerator(
                at: path.url,
                includingPropertiesForKeys: nil,
                options: enumeratorOptions
            ))
        }
    }

    /**
     The type of iterator used byt `Path.ChildSequence`. Don't interact with this type directly.
     See `Path.ChildSequence` for more information.
     */
    struct ChildSequenceIterator: IteratorProtocol {
        fileprivate var enumerator: FileManager.DirectoryEnumerator?

        fileprivate init(_ enumerator: FileManager.DirectoryEnumerator?) {
            self.enumerator = enumerator
        }

        /**
         Advances to the next filesytem item and returns it, or `nil` if no next item exists.

         - Returns: The path of next item.
         */
        public mutating func next() -> Path? {
            guard let enumerator = self.enumerator else {
                return nil
            }

            if let childURL = enumerator.nextObject() as? URL {
                let path = try? Path(url: childURL)

                return path
            }
            return nil
        }
    }

    /**
     A type of filesystem entry.
     */
    enum EntryType: CaseIterable {
        /// The type is unknown which means that entry not exist or cannot be resolved.
        case unknown

        /// The path represents a file.
        case file

        /// The path represents a pipe.
        case pipe

        /// The path represents a directory.
        case directory

        /// The path represents a symbolic link.
        case symlink
    }

    /**
     An error that occurs during initialize and operations with `Path` instances.
     */
    enum Error: Swift.Error {
        /**
         An indication that *path* cannot be resolved.

         - Parameter path: The supplied path which is cannot be resolved.
         */
        case cannotResolvePath(_ path: String)

        /**
         An indication that a URL has unsupported scheme.

         - Parameter scheme: The unsupported scheme.
         */
        case invalidURLScheme(_ scheme: String)

        /**
         An indication that user provided invalid *argument* value.

         - Parameters:
            - arg: The name of invalid argument.
            - description: The error description.
         */
        case invalidArgumentValue(arg: String, _ description: String)

        /// Retrieve the localized description for this error.
        public var localizedDescription: String {
            switch self {
            case let .cannotResolvePath(path):
                return "Cannot resolve path: '\(path)'"
            case let .invalidURLScheme(scheme):
                return "URL scheme: '\(scheme)' is not supported. Only 'file' can be used."
            case let .invalidArgumentValue(arg, description):
                return "Invalid argument: '\(arg)' value. \(description)"
            }
        }
    }

    /**
     A filesystem entry permission representation.
     */
    struct Permissions: Equatable, OptionSet, CustomStringConvertible {
        /// POSIX permission representation.
        public let rawValue: Int

        /// Octal permissions notation (eg: `664`).
        public var octalString: String {
            String(rawValue, radix: 8)
        }

        /// Permisions string representation (eg: `"rw-rw-r--"`)
        public var description: String {
            (contains(.userRead) ? "r" : "-")
                + (contains(.userWrite) ? "w" : "-")
                + (contains(.userExecute) ? "x" : "-")
                + (contains(.groupRead) ? "r" : "-")
                + (contains(.groupWrite) ? "w" : "-")
                + (contains(.groupExecute) ? "x" : "-")
                + (contains(.othersRead) ? "r" : "-")
                + (contains(.othersWrite) ? "w" : "-")
                + (contains(.othersExecute) ? "x" : "-")
        }

        /**
         Creates a permissions instance from POSIX representation.

         - Parameter posix: Permissions POSIX reference.
         */
        public init(rawValue posix: Int) {
            self.rawValue = posix
        }

        /// A mask for user read permission.
        public static let userRead = Permissions(rawValue: 1 << 8)

        /// A mask for user write permission.
        public static let userWrite = Permissions(rawValue: 1 << 7)

        /// A mask for user execute permission.
        public static let userExecute = Permissions(rawValue: 1 << 6)

        /// A mask for group read permission.
        public static let groupRead = Permissions(rawValue: 1 << 5)

        /// A mask for group write permission.
        public static let groupWrite = Permissions(rawValue: 1 << 4)

        /// A mask for group execute permission.
        public static let groupExecute = Permissions(rawValue: 1 << 3)

        /// A mask for others read permission.
        public static let othersRead = Permissions(rawValue: 1 << 2)

        /// A mask for others write permission.
        public static let othersWrite = Permissions(rawValue: 1 << 1)

        /// A mask for others execute permission.
        public static let othersExecute = Permissions(rawValue: 1)

        /// A common mask for user only read and write permissions.
        public static let userRW = Permissions(rawValue: 0o600)

        /// A common mask for user only read, write and execute permissions.
        public static let userRWX = Permissions(rawValue: 0o700)

        /// A common mask for all read and user only write permissions.
        public static let userRW_allR = Permissions(rawValue: 0o644)

        /// A common mask for all execute and user only read, write permissions.
        public static let userRWX_allX = Permissions(rawValue: 0o711)

        /// A common mask for all read, execute and user only write permissions.
        public static let userRWX_allRX = Permissions(rawValue: 0o755)
    }
}
