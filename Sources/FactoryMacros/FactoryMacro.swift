//
//  FactoryMacro.swift
//
//
//  Created by Maxence Mottard on 11/08/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FactoryMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let decl = declaration.as(StructDeclSyntax.self) else {
            return []
        }

        let entityClassName = decl.name
        let factoryClassName = TokenSyntax.identifier("Factory")
        let modifier = getModifiers(modifiers: decl.modifiers)

        let classDecl: DeclSyntax = """
        \(raw: modifier)class \(raw: factoryClassName.text) {
            private static let faker = Faker(locale: "en")

            \(raw: makeDefaultValues(decl.memberBlock.members, modifier: modifier))

            \(raw: modifier)static func create(
                \(raw: makeCreateMethodParameters(decl.memberBlock.members))
            ) -> \(raw: entityClassName.text) {
                .init(
                    \(raw: makeCreateMethodBody(decl.memberBlock.members))
                )
            }

            \(raw: modifier)static func create(count: Int) -> [\(raw: entityClassName.text)] {
                (0 ..< count).map { _ in self.create() }
            }
        }
        """

        return [classDecl]
    }

    private static func makeDefaultValues(_ members: MemberBlockItemListSyntax, modifier: String) -> String {
        members.compactMap { member in
            guard let syntax = member.decl.as(VariableDeclSyntax.self),
                  let bindings = syntax.bindings.as(PatternBindingListSyntax.self),
                  let pattern = bindings.first?.as(PatternBindingSyntax.self),
                  let identifier = (pattern.pattern.as(IdentifierPatternSyntax.self))?.identifier,
                  let type = (pattern.typeAnnotation?.as(TypeAnnotationSyntax.self))?.type,
                  let fakeData = makeFakeryValue(type: type) else {
                return nil
            }

            return "\(modifier)static let \(identifier): \(type) = \(fakeData)"
        }
        .joined(separator: "\n")
    }

    private static func makeCreateMethodParameters(_ members: MemberBlockItemListSyntax) -> String {
        members.compactMap { member in
            guard let syntax = member.decl.as(VariableDeclSyntax.self),
                  let bindings = syntax.bindings.as(PatternBindingListSyntax.self),
                  let pattern = bindings.first?.as(PatternBindingSyntax.self),
                  let identifier = (pattern.pattern.as(IdentifierPatternSyntax.self))?.identifier,
                  let type = (pattern.typeAnnotation?.as(TypeAnnotationSyntax.self))?.type else {
                return nil
            }

            return "\(identifier): \(type)? = nil"
        }
        .joined(separator: ",\n")
    }

    private static func makeCreateMethodBody(_ members: MemberBlockItemListSyntax) -> String {
        members.compactMap { member in
            guard let syntax = member.decl.as(VariableDeclSyntax.self),
               let bindings = syntax.bindings.as(PatternBindingListSyntax.self),
               let pattern = bindings.first?.as(PatternBindingSyntax.self),
               let identifier = (pattern.pattern.as(IdentifierPatternSyntax.self))?.identifier,
               let type = (pattern.typeAnnotation?.as(TypeAnnotationSyntax.self))?.type,
               let fakeData = makeFakeryValue(type: type) else {
                return nil
            }

            return "\(identifier): \(identifier) ?? \(fakeData)"
        }
        .joined(separator: ",\n")
    }

    private static func makeFakeryValue(type: TypeSyntax) -> String? {
        switch type.description.lowercased() {
        case "string":
            return "faker.lorem.word()"
        case "int":
            return "faker.number.randomInt()"
        case "double":
            return "faker.number.randomDouble()"
        case "float":
            return "faker.number.randomFloat()"
        case "bool":
            return "faker.number.randomBool()"
        case "date":
            return "Date()"
        default:
            return nil
        }
    }

    private static func getModifiers(modifiers: DeclModifierListSyntax?) -> String {
        let publicModifier = modifiers?
            .compactMap { $0.as(DeclModifierSyntax.self) }
            .map(\.name)
            .map(\.text)
            .first { $0 == "public" }

        if let publicModifier {
            return publicModifier + " "
        }

        return ""
    }
}

@main
struct FactoryMacro_Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FactoryMacro.self,
    ]
}
