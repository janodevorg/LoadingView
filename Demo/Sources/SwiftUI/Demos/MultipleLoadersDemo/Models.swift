import Foundation

struct User: Hashable {
    let name: String
    let avatar: String
    let status: String
}

struct Stats: Hashable {
    let posts: Int
    let followers: Int
    let following: Int
}