
# CommandLineAPI
![badge-swift][] ![badge-platforms][] [![badge-spm][]][spm-link] [![badge-ci][]][ci] [![badge-docs][]][docs] [![badge-licence][]][licence]

<!-- TODO link to documentation coverage -->
<!-- determine right swift version 5.2 or 5.1? -->

The library that can help you create a command line applications. This library is inspired by [Swiftline](https://github.com/nsomar/Swiftline) and [Path.swift](https://github.com/mxcl/Path.swift).

## Features

* [Path struct](#path) for handling files and directories.
* [String styles](#string-styles) which helps styling the strings before print them to the terminal.
* [Prompt functions](#prompt-functions) for process input and output in the terminal.
* [Functions for run](#run) an external commands and read its standard output.
* Read and write [environment](#env) variables.
* Parse command line [arguments](#args).

## Path

Path is a simple way for accessing, reading nad writing files and directories.

Crate a Path instance:
```swift
// Path are always absolute
let path = try Path("/Users/hejki/tools/README") // absolute path from root /
let pathFromURL = try Path(url: URL(fileURLWithPath: "/Users/hejki/tools/README"))

try Path("~/Downloads") // path relative to current user home
try Path("~tom/Downloads") // path relative to another user home
try Path("Package.swift") // path relative to current working directory
Path(".stool/config.yaml", relativeTo: .home) // relative path to another path
```

Shortcut paths for system directories:
```swift
Path.root    // File system root
Path.home    // Current user's home
Path.current // Current working directory
```

Path components and path chaining:
```swift
// Paths can be joined with appending funcion or + operator
let readme = Path.home.appending("tools") + "README.md"

readme.url // URL representation
readme.string // Absolute path string
readme.pathComponents // ["Users", "hejki", "tools", "README.md"]
readme.extension // md
readme.basename // README.md
readme.basenameWithoutExtension // README
readme.parent // Path("/Users/hejki/tools")
```

Iterate over the directory content:
```swift
for path in Path.current.content {
    print(path)
}
```

Access to file and directory attributes:
```swift
readme.exist // `true` if this path represents an actual filesystem entry
readme.type // The type of filesystem entry. Can be .file, .directory, .symlink, etc.

let attributes = readme.attributes

attributes.creationDate     // item's creation date
attributes.modificationDate // item's last modify date
attributes.extensionHidden  // item's extension is hidden
attributes.userName         // item's owner user name
attributes.groupName        // item's owner group name
attributes.permissions      // item's permissions
attributes.size             // item's size in bytes (read-only)
```

Create, copy, move and delete filesystem items:
```swift
let downloads = Path("Downloads/stool", relativeTo: .home)
let documents = try Path.home.createDirectory("Projects") // Creates a directory

try downloads.touch() // Creates an empty file, or updates its modification time
    .copy(to: documents, overwrite: true) // Copy that file to documents directory
    .rename(to: "stool.todo") // Rename that file
try downloads.delete(useTrash: false) // Delete original file, or move to trash
```

Read and write filesystem item's content:
```swift
// Read content functions
let string = String(contentsOf: readme) // File content as String
let data = Data(contentsOf: readme) // File content as Data

// Write functions on Data and String
try "Hi!".write(to: path, append: false, atomically: false, encoding: .utf8)
try Data().write(to: path, append: false, atomically: false)

// Write functions on Path
try path.write(text: "README", append: false, encoding: .utf8)
try path.write(data: Data(), append: false)
```

## String Styles

String styles helps styling the strings before printing them to the terminal. You can change the text color, the text background color and the text style. String styles works in string interpolation and for implementations of `StringProtocol`.

Change style of string part using string interpolation extension:
```swift
print("Result is \(result.exitStatus, styled: .fgRed)")
print("Result is \(result.exitStatus, styled: .fgRed, .italic)") // multiple styles at once
```

Implementations of `StringProtocol` can use styles directly:
```swift
print("Init...".styled(.bgMagenta, .bold, .fgRed))
```

## Prompt Functions

### Print

Functions for print strings to standard output/error or for read input from standard input.
```swift
CLI.print("Print text to console without \n at end.")
CLI.println("Print text to console with terminating newline.")
CLI.print(error: "Print error to console without \n at end.")
CLI.println(error: "Print error to console with terminating newline.")

// read user input
let fileName = CLI.read()
```

Handler for this functions can be changed by setting `CLI.prompt` variable. This can be handle for tests, for example:
```swift
class TestPromptHandler: PromptHandler {
    func print(_ string: String) {
        XCTAssertEqual("test print", string)
    }
    ...
}

CLI.prompt = TestPromptHandler()
```

### Ask

Ask presents the user with a prompt and waits for the user input.
```swift
let toolName = CLI.ask("Enter tool name: ")
```

Types that confirms ExpressibleByStringArgument can be returned from ask.
```swift
let timeout = CLI.ask("Enter timeout: ", type: Int.self)

// If user enters something that cannot be converted to Int, a new prompt is diplayed,
// this prompt will keep displaying until the user enters an Int:
// $ Enter timeout: No
// $ Please enter a valid Int.
// $ 2.3
// $ Please enter a valid Int.
// $ 2
```

Prompt can be customized througt ask options.
```swift
// to specify default value which is used if the user only press Enter key
CLI.ask("Output path [/tmp]?\n ", options: .default("/tmp"))

// use .confirm() if you require value confirmation
CLI.ask("Remove file? ", type: Bool.self, options: .confirm())
.confirm(message: "Use this value?\n ") // to specify custom message
.confirm(block: { "Use \($0) value? " }) // to specify custom message with entered value

// add some .validator() to validate an entered value
let positive = AskOption<Int>.validator("Value must be positive.") { $0 > 0 }
let maxVal = AskOption<Int>.validator("Max value is 100.") { $0 <= 100 }

CLI.ask("Requested value: ", options: positive, maxVal)

// you can use some predefined validators
.notEmptyValidator() // for Strings
.rangeValidator(0...5) // for Comparable instances

// options can be combined together
let i: Int = CLI.ask("Value: ", options: .default(3), .confirm(), positive)
```

### Choose

    TODO: not implemented yet.

## Run

Run provides a quick way to run an external command and read its standard/error output and exit status.

```swift
let result = CLI.run("ls -al")
print(result.exitStatus)
print(result.stdout)
```

Each command can be run with one of available executors. The executor defines how to run command.

* `.default` executor is dedicated to non-interactive, short running tasks. This executor runs the command and consumes all its outputs. Command outputs will be available after task execution in task result. This executor is default for `CLI.run` functions.
* `.dummy` executor which only prints command to `CLI.println`. You can specify returned stdout, stderr strings and exitStatus.
* `.interactive` executor runs commands with it's standard output and error outputs redirected to system standard output and error. This executor can handle user's inputs from system standard input. The command outputs will not be recorded.

For more complex executions use `Command` type directly:
```swift
let command = CLI.Command(
    ["swift", "build"],
    executor: .interactive,
    workingDirectory: Path.home + "/Projects/CommandLineAPI",
    environment: ["PATH": "/usr/bin/"]
)

let result = command.execute()
```

## Env

Read and write the environment variables passed to the script:
```swift
// Array with all envirnoment keys
CLI.env.keys

// Get environment variable
CLI.env["PATH"]
```
<!-- TODO: not implemented yet. -->
<!-- // Set environment variable -->
<!-- CLI.env["PATH"] = "~/bin" -->

## Args

Returns the arguments passed to the script.
```swift
// For example when calling `stool init -s default -q -- tool`
// CLI.args contains following results

CLI.args.all == ["stool", "init", "-s", "default", "-q", "--", "tool"]
CLI.args.command == "stool"
CLI.args.flags == ["s": "default", "q": ""]
CLI.args.parameters == ["init", "tool"]
```

## Instalation

To install CommandLineAPI for use in a Swift Package Manager powered tool, add CommandLineAPI as a dependency to your `Package.swift` file. For more information, please see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).
```swift
.package(url: "https://github.com/Hejki/CommandLineAPI", from: "0.1.0")
```

## Alternatives

#### for path handling
* [Path.swift](https://github.com/mxcl/Path.swift) by Max Howell
* [Pathos](https://github.com/dduan/Pathos) by Daniel Duan
* [PathKit](https://github.com/kylef/PathKit) by Kyle Fuller
* [Files](https://github.com/JohnSundell/Files) by John Sundell
* [Utility](https://github.com/apple/swift-package-manager) by Apple

#### for command line tools

* [Swiftline](https://github.com/nsomar/Swiftline) by Omar Abdelhafith
* [Commander](https://github.com/kylef/Commander) by Kyle Fuller 

[badge-swift]: https://img.shields.io/badge/Swift-5.1-orange.svg?logo=swift?style=flat
[badge-spm]: https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat
[spm-link]: https://swift.org/package-manager
[badge-platforms]: https://img.shields.io/badge/platform-mac-lightgray.svg?style=flat
[badge-ci]: https://travis-ci.com/Hejki/CommandLineAPI.svg
[ci]: https://travis-ci.com/Hejki/CommandLineAPI
[badge-licence]: https://img.shields.io/badge/license-MIT-black.svg?style=flat
[licence]: https://github.com/Hejki/CommandLineAPI/blob/master/LICENSE
[docs]: https://hejki.github.io/CommandLineAPI
[badge-docs]: https://hejki.github.io/CommandLineAPI/badge.svg?sanitize=true