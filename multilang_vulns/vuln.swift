import Foundation
func run(input: String) {
    // Insecure Web Request (SSRF potential)
    let url = URL(string: input)!
    let data = try! Data(contentsOf: url)
}\n