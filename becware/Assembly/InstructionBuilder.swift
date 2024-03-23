import Foundation

@resultBuilder
enum InstructionBuilder {
    static func buildBlock(_ components: Assemblable...) -> [Assemblable] {
        components
    }

    static func buildBlock(_ components: [Assemblable]...) -> [Assemblable] {
        components.flatMap { $0 }
    }

    static func buildArray(_ components: [Assemblable]) -> [Assemblable] {
        components
    }

    static func buildArray(_ components: [[Assemblable]]) -> [Assemblable] {
        components.flatMap { $0 }
    }

    static func buildOptional(_ component: [Assemblable]?) -> [Assemblable] {
        component ?? []
    }

    static func buildPartialBlock(first: Assemblable) -> [Assemblable] {
        [first]
    }

    static func buildPartialBlock(accumulated: [Assemblable], next: Assemblable) -> [Assemblable] {
        var accumulated = accumulated
        accumulated.append(next)
        return accumulated
    }

    static func buildPartialBlock(first: [Assemblable]) -> [Assemblable] {
        first
    }

    static func buildPartialBlock(accumulated: [Assemblable], next: [Assemblable]) -> [Assemblable] {
        accumulated + next
    }
}
