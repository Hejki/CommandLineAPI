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
 Namespace for all commandline related functions and objects.
 */
public enum CLI {
    /**
     Prompt handler for print output and read input for command line.
     Initial `CLI.prompt` value is set to print to stdout and stderr, and read from stdin.

     - Note: Custom `PromptHandler` can be useful in tests.
     */
    public static var prompt: PromptHandler = ConsolePromptHandler()

    /**
     Flag for globally enable or disable the `StringStyle` formatting.
     If set to `false`, string styles not be evaluated inside strings.
     Default is `true`.
     */
    public static var enableStringStyles: Bool = true

    /// Access to environment variables of current process.
    public static var env = Environment()

    /// Access to parsed command line arguments for current process.
    public static let args = Arguments()
}

// MARK: - String Style
private let startOfCode = "\u{001B}["
private let endOfCode = "m"
private let resetCode = "\u{001B}[0m"

public extension CLI {
    /**
     Available string styles.

     This styles can be used in string iterpolation:
     ```swift
     print("Result is \(result.exitCode, styled: .fgRed, .italic)")
     ```

     or can be used with any instances of `StringProtocol`:
     ```swift
     print("Init...".styled(.bgMagenta, .bold, .fgRed))
     ```

     - Note: Uses SGR parameters from [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
     */
    struct StringStyle {
        private let code: String
        fileprivate var escapeCode: String {
            "\(startOfCode)\(code)\(endOfCode)"
        }

        func enrich<S: StringProtocol>(_ string: S) -> String {
            guard CLI.enableStringStyles else {
                return string.description
            }
            return "\(escapeCode)\(string)\(resetCode)"
        }

        // MARK: Text Styles and Decorations
        /// Bold or increased intensity style.
        public static var bold = StringStyle(code: "1")

        /// Faint or decreased intensity style.
        public static var faint = StringStyle(code: "2")

        /// Italic text style.
        public static var italic = StringStyle(code: "3")

        /// Underline text decoration.
        public static var underline = StringStyle(code: "4")

        /// Style for swap foreground and background colors.
        public static var inverse = StringStyle(code: "7")

        /// Strikethrough text decoration.
        public static var strikethrough = StringStyle(code: "9")

        // MARK: Text Foreground Colors
        /// Black foreground color.
        public static var fgBlack = StringStyle(code: "30")

        /// Red foreground color.
        public static var fgRed = StringStyle(code: "31")

        /// Green foreground color.
        public static var fgGreen = StringStyle(code: "32")

        /// Yellow foreground color.
        public static var fgYellow = StringStyle(code: "33")

        /// Blue foreground color.
        public static var fgBlue = StringStyle(code: "34")

        /// Magenta foreground color.
        public static var fgMagenta = StringStyle(code: "35")

        /// Cyan foreground color.
        public static var fgCyan = StringStyle(code: "36")

        /// White foreground color.
        public static var fgWhite = StringStyle(code: "37")

        // MARK: Text Background Colors
        /// Black background color.
        public static var bgBlack = StringStyle(code: "40")

        /// Red background color.
        public static var bgRed = StringStyle(code: "41")

        /// Green background color.
        public static var bgGreen = StringStyle(code: "42")

        /// Yellow background color.
        public static var bgYellow = StringStyle(code: "43")

        /// Blue background color.
        public static var bgBlue = StringStyle(code: "44")

        /// Magenta background color.
        public static var bgMagenta = StringStyle(code: "45")

        /// Cyan background color.
        public static var bgCyan = StringStyle(code: "46")

        /// White background color.
        public static var bgWhite = StringStyle(code: "47")

        // MARK: Custom Color Functions
        /**
         Creates a bright version of text color.

         - Parameter style: One of text color styles.
         - Precondition: *style* must be one of foreground or background colors.
         */
        public static func bright(_ style: StringStyle) -> StringStyle {
            let code = Int(style.code) ?? 0
            precondition((code >= 30 && code < 38) || (code >= 40 && code < 48), "Bright text color can only accept color codes.")

            return StringStyle(code: "\(code);1")
        }

        /**
         Creates a foreground text 8-bit color style with specific color code.

         - Parameter colorCode: The specific color code in interval `0..<256`
         - Precondition: *colorCode* must be one ininterval `0..<265`
         */
        public static func fg(_ colorCode: Int) -> StringStyle {
            precondition(colorCode >= 0 && colorCode < 256, "Custom foreground color code must be in interval from 0 t0 255.")
            return StringStyle(code: "38;5;\(colorCode)")
        }

        /**
         Creates a foreground text "true color" style with define color code
         for each color component (red, green and blue).

         - Parameters:
             - red: The color code for red component (in interval `0..<256`).
             - green: The color code for green component (in interval `0..<256`).
             - blue: The color code for blue component (in interval `0..<256`).
         - Precondition: *red*, *green* and *blue* must be one ininterval `0..<265`
         */
        public static func fg(r red: Int, g green: Int, b blue: Int) -> StringStyle {
            precondition(red >= 0 && red < 256, "Custom foreground color red code must be in interval from 0 t0 255.")
            precondition(green >= 0 && green < 256, "Custom foreground green color code must be in interval from 0 t0 255.")
            precondition(blue >= 0 && blue < 256, "Custom foreground blue color code must be in interval from 0 t0 255.")
            return StringStyle(code: "38;2;\(red);\(green);\(blue)")
        }

        /**
         Creates a bacground text 8-bit color style with specific color code.

         - Parameter colorCode: The specific color code in interval `0..<256`
         - Precondition: *colorCode* must be one ininterval `0..<265`
         */
        public static func bg(_ colorCode: Int) -> StringStyle {
            precondition(colorCode >= 0 && colorCode < 256, "Custom background color code must be in interval from 0 t0 255.")
            return StringStyle(code: "48;5;\(colorCode)")
        }

        /**
         Creates a background text "true color" style with define color code
         for each color component (red, green and blue).

         - Parameters:
             - red: The color code for red component (in interval `0..<256`).
             - green: The color code for green component (in interval `0..<256`).
             - blue: The color code for blue component (in interval `0..<256`).
         - Precondition: *red*, *green* and *blue* must be one ininterval `0..<265`
         */
        public static func bg(r red: Int, g green: Int, b blue: Int) -> StringStyle {
            precondition(red >= 0 && red < 256, "Custom background color red code must be in interval from 0 t0 255.")
            precondition(green >= 0 && green < 256, "Custom background green color code must be in interval from 0 t0 255.")
            precondition(blue >= 0 && blue < 256, "Custom background blue color code must be in interval from 0 t0 255.")
            return StringStyle(code: "48;2;\(red);\(green);\(blue)")
        }
    }
}

extension Array where Element == CLI.StringStyle {

    /// Add all `StringStyle`s in array to specified string.
    func enrich<S: CustomStringConvertible>(_ string: S) -> String {
        if isEmpty || !CLI.enableStringStyles {
            return string.description
        }

        return map { $0.escapeCode }
            .joined()
            .appending("\(string)\(resetCode)")
    }
}

/// Add support for strings style with `StringStyle` constants.
public extension String.StringInterpolation {

    /**
     Interpolates the given value's textual representation with defined styles into the string literal being created.

     Do not call this method directly It is used by the compiler when interpreting string interpolations.
     Instead, use string interpolation to create a new string by including values, literals, variables,
     or expressions enclosed in parentheses, prefixed by a backslash `\(…, style:)`.

     - Parameters:
        - value: The value to be styled.
        - style: What styles to be apply to *value*.
     */
    mutating func appendInterpolation<S: CustomStringConvertible>(_ value: S, style: CLI.StringStyle...) {
        appendLiteral(style.enrich(value))
    }
}

/// Add support for strings style with `StringStyle` constants.
public extension StringProtocol {

    /**
     Creates a string which is enriched by specified text *styles*.

     - Parameter styles: What styles to be apply to this string.
     - Returns: The string with style escape codes.
     */
    func styled(_ styles: CLI.StringStyle...) -> String {
        return styles.enrich(self)
    }
}

// MARK: - Print - Prompt Function
public extension CLI {
    /**
     Print string to defined prompt (default is `stdout`). Printed string is not terminated by newline.

     - Parameter string: The text to print.
     - SeeAlso: `CLI.prompt` for set preferred `PromptHandler`.
     */
    @inlinable
    static func print(_ string: String) {
        CLI.prompt.print(string)
    }

    /**
     Print string with a new line terminator to defined prompt (default is `stdout`).

     - Parameter string: The text to print.
     - SeeAlso: `CLI.prompt` for set preferred `PromptHandler`.
     */
    @inlinable
    static func println(_ string: String) {
        CLI.prompt.print(string + "\n")
    }

    /**
     Print string to defined error prompt (default is `stderr`). Printed string is not terminated by newline.

     - Parameter string: The error text to print.
     - SeeAlso: `CLI.prompt` for set preferred `PromptHandler`.
     */
    @inlinable
    static func print(error string: String) {
        CLI.prompt.print(error: string)
    }

    /**
     Print string with a new line terminator to defined error prompt (default is `stderr`).

     - Parameter string: The error text to print.
     - SeeAlso: `CLI.prompt` for set preferred `PromptHandler`.
     */
    @inlinable
    static func println(error string: String) {
        CLI.prompt.print(error: string + "\n")
    }
}

/**
 A type that can handle print and read functions from command line prompt.
 */
public protocol PromptHandler {
    /**
     Print a string to standart output (`stdout`).

     - Parameter string: The string to be printed to standard output.
     - Note: Newline character is not printed automatically.
     */
    func print(_ string: String)

    /**
     Print an error string to error output (`stderr`).

     - Parameter string: The error string to be printed to error output.
     - Note: Newline character is not printed automatically.
     */
    func print(error string: String)

    /**
     Read line from standard input (stdin).
     Returned string must have stripped termination newline.
     If input cannot be read then must returns empty string.

     - Returns: String from input
     */
    func read() -> String
}

/// Default implementation of `PromptHandler` to print to console.
private struct ConsolePromptHandler: PromptHandler {
    func print(_ string: String) {
        Swift.print(string, separator: "", terminator: "")
    }

    func print(error string: String) {
        if let data = string.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }

    func read() -> String {
        return readLine(strippingNewline: true) ?? ""
    }
}

// MARK: - Ask - Prompt Function
public extension CLI {

    /**
     Displays prompt to the user.

     - Parameters:
        - prompt: The message to display.
        - options: The prompt customization options.
     - Returns: The string enters from the user.
     */
    static func ask(_ prompt: String, options: AskOption<String>...) -> String {
        return Ask(options) {
            $0.print(prompt)
        }.run()
    }

    /**
     Displays prompt to the user.

     If the user enters a string wich cannot be converted to the expected type,
     `ask` will keep prompting until a corect value has been entered.

     - Parameters:
        - prompt: The message to display.
        - type: The value type to be expected from the user.
        - options: The prompt customization options.
     - Returns: The converted string enters from the user.
     */
    static func ask<T: ExpressibleByStringArgument>(_ prompt: String, type: T.Type = T.self, options: AskOption<T>...) -> T {
        return Ask(options) {
            $0.print(prompt)
        }.run()
    }

    /**
     Options for `CLI.ask(_:options:)` functions which can customize value handling and custom prompt validations.

     This options are passed to `CLI.ask(_:options:)` functions, for example:
     ```swift
     // Define a default value and require the entered value confirmation.
     CLI.ask("Choose directory [/tmp]: ", options: .default("/tmp"), .confirm())

     // Prints:
     // $ Choose directory [/tmp]: <<user input>>
     // $ Are you sure? <<y>>
     // The result is "<<user input>>" or "/tmp" if the user only press Enter key.
     ```
     */
    enum AskOption<T: ExpressibleByStringArgument> {
        /**
         Type alias for validator function. This function takes the parsed value as parameter
         and returns a Boolean value to indicate if this *value* is valid or not.
         */
        public typealias Validator = (T) -> Bool

        /**
         Defines a default value for `ask` result if the user only press Enter key.

         - Parameter value: The default value.
         */
        case `default`(_ value: T)

        /**
         Defines that the `ask` result will require confirmation. Parameters are used to define confirmation prompt.

         ```swift
         // Different use of parameters and its confirmation messages
         .confirm() // "Are you sure? "
         .confirm(message: "Realy?\n") // "Realy?\n"
         .confirm(block: { "Use \($0)? " }) // "Use <<user input>>? "
         ```

         - Parameters:
            - message: The closure to define static confirmation string.
            - block: The closure to define dynamic confirmation string with entered value as parameter.
         */
        case confirm(message: @autoclosure () -> String = "Are you sure? ", block: ((String) -> String)? = nil)

        /**
         Defines a validator for validate the entered value.

         ```swift
         .validator("Entered value must be greater than 0.", { $0 > 0 })
         .validator("Value cannot be empty!", { !$0.isEmpty() })
         ```

         - Parameters:
            - message: The error message to show if the entered value is not valid.
            - validator: The custom `AskOption.Validator` which returns `true` for valid value or `false` for invalid.
         */
        case validator(_ message: String, _ validator: Validator)
    }

    private struct Ask<T: ExpressibleByStringArgument> {
        private typealias ValidatorTuple = (message: String, validate: AskOption<T>.Validator)

        private let printPrompt: (PromptHandler) -> Void
        private var defaultValue: T?
        private var confirmMessage: ((String) -> String)?
        private var validators = [ValidatorTuple]()

        init(_ options: [AskOption<T>] = [], _ prompt: @escaping (PromptHandler) -> Void) {
            self.printPrompt = prompt

            for option in options.compactMap({ $0.option }) {
                switch option {
                case let .default(value):
                    self.defaultValue = value
                case let .confirm(_, block) where block != nil:
                    self.confirmMessage = block
                case let .confirm(message, _):
                    self.confirmMessage = { _ in message() }
                case let .validator(m, v):
                    self.validators.append((m, v))
                }
            }
        }

        func run() -> T {
            printPrompt(CLI.prompt)

            while true {
                guard let promptResult = readValidValue() else {
                    continue
                }

                if let msg = confirmMessage?(promptResult.read) {
                    if CLI.ask(msg) {
                        return promptResult.value
                    }
                    printPrompt(CLI.prompt)
                } else {
                    return promptResult.value
                }
            }
        }

        func readValidValue() -> (read: String, value: T)? {
            let stringValue = CLI.prompt.read()
            if let value = defaultValue, stringValue == "" {
                return (stringValue, value)
            }

            guard let value = T(stringArgument: stringValue) else {
                CLI.prompt.print("Please enter a valid \(T.self).\n: ")
                return nil
            }

            for validator in validators {
                if !validator.validate(value) {
                    CLI.prompt.print("\(validator.message)")
                    return nil
                }
            }
            return (stringValue, value)
        }
    }
}

/**
 A type that can be initialized with a string argument.
 Any type that extends this can be used in `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
 */
public protocol ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     - Parameter stringArgument: The value of the new instance.
     */
    init?(stringArgument: String)
}

extension String: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
     */
    @inlinable
    public init?(stringArgument arg: String) {
        self.init(arg)
    }
}

extension Int: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
     */
    @inlinable
    public init?(stringArgument arg: String) {
        self.init(arg)
    }
}

extension Bool: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.
     String values `y`, `yes` and `true` are represents the boolean value `true`,
     values `n`, `no` and `false` are represents the boolean value `false`,
     other values are returned as uninitialized object.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
     */
    public init?(stringArgument arg: String) {
        let str = arg.lowercased()
        if str == "y" || str == "yes" || str == "true" {
            self.init(true)
        } else if str == "n" || str == "no" || str == "false" {
            self.init(false)
        } else {
            return nil
        }
    }
}

extension Double: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
     */
    @inlinable
    public init?(stringArgument arg: String) {
        self.init(arg)
    }
}

extension Float: ExpressibleByStringArgument {

    /**
     Creates an instance initialized to the given string value.

     Do not call this initializer directly. It is used by the `CLI.ask(_:options:)` and `CLI.choose(_:choices:)` functions.
     */
    @inlinable
    public init?(stringArgument arg: String) {
        self.init(arg)
    }
}

private protocol AnyAskOption {
    associatedtype OptionType: ExpressibleByStringArgument

    var option: CLI.AskOption<OptionType> { get }
}

extension CLI.AskOption: AnyAskOption {
    var option: CLI.AskOption<T> { self }
}

// MARK: Predefined Prompt Validators
public extension CLI.AskOption where T == String {

    /**
     Predefined validator for validate if entered string is not empty.

     - Parameter message: The error message to display to the user if entered value is empty string.
     - Returns: The created validator.
     */
    @inlinable
    static func notEmptyValidator(_ message: String = "The entered value cannot be empty!\n: ") -> CLI.AskOption<T> {
        return .validator(message) { !$0.isEmpty }
    }
}

public extension CLI.AskOption where T: Comparable {

    /**
     Predefined validator for validate if entered value is satisfy specified *range*.

     - Parameters:
        - range: The range for specify value bounds.
        - message: The error message to display to the user if value is not valid.
     - Returns: The created validator.
     */
    @inlinable
    static func rangeValidator<R>(_ range: R, _ message: String? = nil) -> CLI.AskOption<T> where R: RangeExpression, R.Bound == T {
        return .validator(
            message ?? "The entered value is not in range \(range)!\n: ",
            range.contains
        )
    }
}

// MARK: - Choose - Prompt Function
public extension CLI {

    /**
     Displays a menu of items to the user to choose from.

     - Parameters:
        - prompt: The message to display.
        - choices: The items to choose from.
     - Returns: An one of the *choices* that the user choose.
     - Precondition: The *choices* must be non empty array.
     */
    static func choose(_ prompt: String, choices: [String]) -> String {
        precondition(choices.count > 0, "Number of choices must be greater than 0.")

        let range = 1 ... choices.count
        let validator = AskOption<String>.validator("invalid option\n\(prompt)") {
            range.contains(Int($0) ?? 0)
        }

        let result = Ask<String>([validator]) { promptHandler in
            for (offset, choose) in choices.enumerated() {
                promptHandler.print("\(offset + 1)) \(choose)\n")
            }
            promptHandler.print(prompt)
        }.run()

        return choices[Int(result)! - 1]
    }

    /**
     Displays a menu of items to the user to choose from.

     - Parameters:
        - prompt: The message to display.
        - choices: The items to choose from. The choice key will be shown to the user (sorted)
            and dictionary value for that key will be returned from this function.
     - Returns: A value of the one of *choices* that the user choose.
     - Precondition: The *choices* must be non empty dictionary.
     */
    static func choose<T>(_ prompt: String, choices: [String: T]) -> T {
        let keys = Array(choices.keys).sorted()
        let result = choose(prompt, choices: keys)

        return choices[result]!
    }
}

// MARK: - Run Commands
public extension CLI {

    /**
     Run external command with defined executor.

     - Parameters:
        - command: The command to execute.
        - args: The command arguments.
        - executor: The command executor for execute defined command.
     - Returns: A command result with exit status code and parsed stdout and stderr outputs.
     - SeeAlso: `Command.execute()`
     */
    @inlinable
    static func run(_ command: String, _ args: String..., executor: CommandExecutor = .default) -> CommandRunResult {
        return run(command, args: args, executor: executor)
    }

    /**
     Run external command with defined executor.

     - Parameters:
       - command: The command to execute.
       - args: The array with command arguments.
       - executor: The command executor for execute defined command.
     - Returns: A command result with exit status code and stdout and stderr outputs.
     - SeeAlso: `Command.execute()`
     */
    @inlinable
    static func run(_ command: String, args: [String], executor: CommandExecutor = .default) -> CommandRunResult {
        let arguments = command.split(separator: " ").map(String.init) + args
        return Command(arguments, executor: executor).execute()
    }

    /**
     Run `echo -n` command with specified *text*. This command can be used to chain *text* output with
     other commands using `CommandRunResult.pipe(to:_:)`. The executor is `.default`.

     - Parameter text: The text to be printed.
     - Returns: A command result.
     */
    @inlinable
    static func echo(_ text: String) -> CommandRunResult {
        return Command(["echo", "-n", text], executor: .default).execute()
    }

    /**
     Object to hold results from `CLI.run(_:_:executor:)` or `Command.execute()`. The results can be chained to
     another command by using `CommandRunResult.pipe(to:_:)` function or `|` operator.

     This object contains command exist status code and stdout and stderr outputs if available.
     */
    struct CommandRunResult {
        /// The command for this result.
        public let command: Command

        /// The exit code of executed command.
        public let exitCode: Int

        /// The string printed to the standard output by executed command.
        public var stdout: String {
            if let fileHandle = pipe?.fileHandleForReading {
                return String(data: fileHandle.availableData, encoding: .utf8) ?? ""
            }
            return cachedStdout
        }

        /// The string printed to the error output by executed command.
        public let stderr: String

        fileprivate let pipe: Pipe?
        private let cachedStdout: String

        /// Returns `true` if *exitCode* is `0`.
        var isSuccess: Bool {
            exitCode == 0
        }

        fileprivate init(_ command: Command, _ status: Int, out: String = "", err: String = "", pipe: Pipe? = nil) {
            self.command = command
            self.exitCode = status
            self.cachedStdout = out
            self.stderr = err
            self.pipe = pipe
        }

        /**
         Chain output of this result to the another command. The executor of the new command
         will be same as executor which provide this result.

         - Parameters:
            - command: The command to be executed.
            - args: The command arguments.
         - Returns: A new result of the new command.
         */
        public func pipe(to command: String, _ args: String...) -> CommandRunResult {
            return pipe(to: command, args: args)
        }

        /**
         Chain the result to a new command. See `pipe(to:_:)` for more info.
         */
        public func pipe(to command: String, args: [String]) -> CommandRunResult {
            let arguments = command.split(separator: " ").map(String.init) + args
            return self | arguments
        }

        /**
         Chain the result to a new command. See `pipe(to:_:)` for more info.
         */
        public static func | (left: CommandRunResult, right: String) -> CommandRunResult {
            return left.pipe(to: right)
        }

        /**
         Chain the result to a new command. See `pipe(to:_:)` for more info.
         */
        public static func | (left: CommandRunResult, right: [String]) -> CommandRunResult {
            if case .interactive = left.command.executor {
                precondition(false, "The result from interactive executor cannot be used for chaining.")
            }

            guard left.exitCode == 0 else {
                CLI.println(error: "Cannot pipe to command '\(left.command)' because previous command ends with status \(left.exitCode).")
                return left
            }
            return Command(right, fromPipe: left).execute()
        }
    }

    /**
     The command which to be executed.

     This struct holds all settings for command execution and can be created througt
     `CLI.run(_:_:executor:)` functions or directly.
     ```swift
     CLI.run("echo -n", "Hi!")
     // is equivalent to
     Command(["echo", "-n", "Hi!"]).execute()
     ```

     - Note: `Command` is more complex than simple `run` function.
        You can specify command working directory or environment variables.
     */
    struct Command: CustomStringConvertible {
        /// The command arguments that should be used to launch the executable.
        public let arguments: [String]

        /// The command executor.
        public let executor: CommandExecutor

        /// The path to working diretory for current command.
        public let workingDirectory: Path

        /// The environment for the command. If this is `nil`, the environment is inherited from the current process.
        public let environment: [String: String]?

        fileprivate let pipe: Pipe?

        /// A textual representation of command wit all arguments.
        public var description: String {
            arguments.joined(separator: " ")
        }

        /**
         Creates an instance of command.

         - Parameters:
            - arguments: The array with all arguments of command.
            - executor: The command executor which will be used to execute command.
            - workingDirectory: The current working directory for executed command.
            - environment: The environment variables for executed command.
         - Note: The parameters *workingDirectory* and *environment* may not be supported in some executors.
         */
        public init(
            _ arguments: [String],
            executor: CommandExecutor = .default,
            workingDirectory: Path = .current,
            environment: [String: String]? = nil
        ) {
            self.arguments = arguments
            self.executor = executor
            self.workingDirectory = workingDirectory
            self.environment = environment
            self.pipe = nil
        }

        fileprivate init(_ arguments: [String], fromPipe previousResult: CommandRunResult) {
            self.arguments = arguments
            self.executor = previousResult.command.executor
            self.workingDirectory = previousResult.command.workingDirectory
            self.environment = previousResult.command.environment
            self.pipe = previousResult.pipe
        }

        /**
         Execute command with given executor.

         - Returns: The command execution result.
         */
        public func execute() -> CommandRunResult {
            return executor.execute(self)
        }
    }

    /**
     Types of supported command executors.
     */
    enum CommandExecutor {
        /**
         Not execute the command, only prints string: "Executed: <<command.description>>" to standard output.
         Returned `CommandRunResult` contains defined parameters with this enum.

         - Parameters:
            - status: The command exit status.
            - stdout: The command standard output.
            - stderr: The command error output.
         */
        case dummy(status: Int = 0, stdout: String = "", stderr: String = "")

        /**
          Execute command and consume all outputs. This outputs can be later read from
         `CommandRunResult.stdout` and `CommandRunResult.stderr`. This executor is suitable for
         non-interactive, short running commands, like `ls`, `echo` etc.
         */
        case `default`

        /**
         Execute command with redirected standard/error outputs to system standard outputs.
         This executor can handle user's inputs from system standard input. The executor returns actual exit status
         of executed command but `stdout` and `stderr` of `CommandRunResult` will be always empty strings.
         */
        case interactive

        fileprivate func execute(_ command: Command) -> CommandRunResult {
            switch self {
            case .default:
                return currentTaskExecute(command)
            case .interactive:
                return interactiveExecute(command)
            case let .dummy(status, stdout, stderr):
                return dummyExecute(command, status, stdout, stderr)
            }
        }

        private func currentTaskExecute(_ command: Command) -> CommandRunResult {
            let process = createProcess(command)
            let (stdout, stderr) = (Pipe(), Pipe())

            process.standardOutput = stdout
            process.standardError = stderr
            if let stdin = command.pipe {
                process.standardInput = stdin
            }

            process.launch()
            process.waitUntilExit()

            return CommandRunResult(
                command,
                Int(process.terminationStatus),
                err: String(data: stderr.fileHandleForReading.availableData, encoding: .utf8) ?? "",
                pipe: stdout
            )
        }

        private func interactiveExecute(_ command: Command) -> CommandRunResult {
            let process = createProcess(command)

            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
            process.standardOutput = FileHandle.standardOutput

            process.launch()
            process.waitUntilExit()

            return CommandRunResult(
                command,
                Int(process.terminationStatus),
                out: "",
                err: ""
            )
        }

        private func createProcess(_ command: Command) -> Process {
            let process = Process()

            process.launchPath = "/usr/bin/env"
            process.arguments = command.arguments

            if let env = command.environment {
                process.environment = env
            }

            if #available(OSX 10.13, *) {
                process.currentDirectoryURL = command.workingDirectory.url
            } else {
                process.currentDirectoryPath = command.workingDirectory.path
            }
            return process
        }

        private func dummyExecute(_ command: Command, _ status: Int, _ stdout: String, _ stderr: String) -> CommandRunResult {
            let pipe = Pipe()

            CLI.println("Executed: \(command)")
            if let data = stdout.data(using: .utf8) {
                pipe.fileHandleForWriting.write(data)
            } else {
                pipe.fileHandleForWriting.write("".data(using: .utf8)!)
            }
            pipe.fileHandleForWriting.closeFile()
            return CommandRunResult(command, status, out: stdout, err: stderr, pipe: pipe)
        }
    }
}

// MARK: - Environment Variables
public extension CLI {

    /**
     A type for handle environment variables.
     */
    struct Environment {

        /// The array of all environment variable keys passed to the script.
        public var keys: [String] {
            return Array(ProcessInfo.processInfo.environment.keys)
        }

        /**
         Accesses the environment variable value at the given key.

         - Parameter key: The environment variable key.
         */
        public subscript(_ key: String) -> String? {
            get {
                guard let raw = getenv(key) else {
                    return nil
                }

                return String(cString: raw)
            }
            set {
                if let value = newValue {
                    setenv(key, value, 1)
                } else {
                    unsetenv(key)
                }
            }
        }
    }
}

// MARK: - Script Argument Parser
public extension CLI {

    /**
     A type that handles the command line arguments passed to the script.

     - Note: The arguments will be parsed only if you access to any attribute that require
        arguments parsing, which is the attributes `command`, `flags` and `parameters`.
        The arguments are parsed only once.
     */
    class Arguments {
        private var cache: ParsedArguments?

        /// An array with all command line arguments passed to the script.
        public let all: [String]

        /**
         Creates an instance with supplied command line arguments, defaults to
         `ProcessInfo.processInfo.arguments`.
         */
        public init(args: [String] = ProcessInfo.processInfo.arguments) {
            self.all = args
        }

        /// The name of the executable that was invoked from the command line.
        public var command: String {
            return parsed.command
        }

        /// Parsed flags will be prepared in a dictionary, the key is the flag and
        /// the value is the flag value.
        public var flags: [String: String] {
            return parsed.flags
        }

        /// List of parameters passed to the script
        public var parameters: [String] {
            return parsed.parameters
        }

        private var parsed: ParsedArguments {
            if let result = cache {
                return result
            }

            var args = all
            let command = args.removeFirst()
            var flags = [String: String]()
            var parameters = [String]()
            var previousArg: Arg?
            var argsTerminated = false

            for argumentString in args {
                let arg = Arg(argumentString)
                defer {
                    previousArg = arg
                }

                if argsTerminated {
                    parameters.append(arg.string)
                } else if arg.isFlagTerminator {
                    argsTerminated = true
                } else if arg.isFlag {
                    flags[arg.name] = ""
                } else if let previousArg = previousArg, previousArg.isFlag {
                    flags[previousArg.name] = arg.name
                } else {
                    parameters.append(arg.name)
                }
            }

            cache = ParsedArguments(
                command: command, flags: flags, parameters: parameters
            )
            return cache!
        }

        private struct ParsedArguments {
            let command: String
            let flags: [String: String]
            let parameters: [String]
        }

        private struct Arg {
            let string: String
            let name: String
            let isFlagTerminator: Bool
            let isFlag: Bool
            let isLongFlag: Bool

            init(_ arg: String) {
                var name: String = arg
                var isFlagTerminator: Bool = false
                var isFlag: Bool = false
                var isLongFlag: Bool = false

                if arg == "--" {
                    isFlagTerminator = true
                } else if arg.hasPrefix("--") {
                    let index = arg.index(arg.startIndex, offsetBy: 2)
                    name = String(arg[index...])
                    isFlag = true
                    isLongFlag = true
                } else if arg.hasPrefix("-") {
                    let index = arg.index(arg.startIndex, offsetBy: 1)
                    name = String(arg[index...])
                    isFlag = true
                }

                self.string = arg
                self.name = name
                self.isFlagTerminator = isFlagTerminator
                self.isFlag = isFlag
                self.isLongFlag = isLongFlag
            }
        }
    }
}
