//
//  StructInit.swift
//  
//
//  Created by Maxence Mottard on 11/08/2023.
//

@attached(member, names: arbitrary)
public macro Factory() = #externalMacro(module: "FactoryMacros", type: "FactoryMacro")
