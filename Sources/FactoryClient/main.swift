import Factory
import Fakery
import Foundation

@Factory
public struct Book {
    var id: Int
    var price: Double
    var range: Float
    var title: String
    var subtitle: String
    var description: String
    var author: String
    var isOpen: Bool
    var lastUsage: Date
}

let entities = Book.Factory.create(count: 3)
let test = Book.Factory.lastUsage

//let faker = Faker(locale: "en")
//faker.date.
