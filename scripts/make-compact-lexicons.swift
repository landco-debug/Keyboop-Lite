#!/usr/bin/env swift
import Foundation

func usage() -> Never {
    fputs("usage: make-compact-lexicons.swift input.json output.lex [input.json output.lex ...]\n", stderr)
    exit(2)
}

let args = Array(CommandLine.arguments.dropFirst())
guard !args.isEmpty, args.count % 2 == 0 else { usage() }

for i in stride(from: 0, to: args.count, by: 2) {
    let input = URL(fileURLWithPath: args[i])
    let output = URL(fileURLWithPath: args[i + 1])
    let data = try Data(contentsOf: input)
    let words = try JSONDecoder().decode([String].self, from: data)

    // Runtime lookup compares UTF-8 bytes, so build order uses exactly the same byte ordering.
    let sorted = words.sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }
    FileManager.default.createFile(atPath: output.path, contents: nil)
    let handle = try FileHandle(forWritingTo: output)
    defer { try? handle.close() }

    var previous: String?
    var unique = 0
    for word in sorted {
        if previous == word { continue }
        guard !word.contains("\n") else {
            throw NSError(domain: "KeyboopLexicon", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "newline in dictionary word: \(word)"])
        }
        if let bytes = word.data(using: .utf8) { try handle.write(contentsOf: bytes) }
        try handle.write(contentsOf: Data([0x0A]))
        previous = word
        unique += 1
    }
    print("compact lexicon: \(input.lastPathComponent) -> \(output.lastPathComponent), words=\(unique)")
}
