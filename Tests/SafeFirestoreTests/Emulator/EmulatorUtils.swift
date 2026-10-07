import Foundation

func clearFirestoreEmulator(
  projectID: String
) async throws {
  let url = URL(string: "http://127.0.0.1:8080/emulator/v1/projects/\(projectID)/databases/(default)/documents")!
  
  var request = URLRequest(url: url)
  request.httpMethod = "DELETE"
  
  let (_, response) = try await URLSession.shared.data(for: request)
  
  guard let httpResponse = response as? HTTPURLResponse,
        (200..<300).contains(httpResponse.statusCode)
          else {
    throw URLError(.badServerResponse)
  }
}

enum FirestoreEmulatorError: Error {
  case unavailable(String)
}

func waitForFirestoreEmulator(
  host: String = "127.0.0.1",
  port: Int = 8080,
  timeout: Duration = .seconds(30)
) async throws {
  let url = URL(string: "http://\(host):\(port)")!
  let clock = ContinuousClock()
  let deadline = clock.now.advanced(by: timeout)
  
  while clock.now < deadline {
    var request = URLRequest(url: url)
    request.timeoutInterval = 1
    
    let result: (_: Data, response: URLResponse)? = try? await URLSession.shared.data(for: request)
    if let response = result?.response, response is HTTPURLResponse {
      // any response means server is up
      return
    }
    
    try await Task.sleep(for: .milliseconds(200))
  }
  
  throw FirestoreEmulatorError.unavailable(
    "Firestore Emulator not available on \(host):\(port)"
  )
}
