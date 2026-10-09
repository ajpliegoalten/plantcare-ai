struct CareSheet: Equatable, Sendable {
    let light: String
    let watering: String
    let humidity: String
    let temperature: String
    let substrate: String
    let fertilizer: String

    var requiredFields: [String] {
        [light, watering, humidity, temperature, substrate, fertilizer]
    }
}
