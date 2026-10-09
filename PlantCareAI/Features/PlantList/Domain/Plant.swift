import Foundation

// Only identity is needed to represent a collection member today.
// The storage feature will extend this model with confirmed plant data.
struct Plant: Identifiable {
    let id: UUID
}
