@preconcurrency import FirebaseFirestore

extension DocumentReference {
  func setData<T: Encodable>(
    from value: T,
    encoder: Firestore.Encoder = Firestore.Encoder()
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      do {
        try setData(from: value, encoder: encoder) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume()
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
  
  func setData<T: Encodable>(
    from value: T,
    merge: Bool,
    encoder: Firestore.Encoder = Firestore.Encoder()
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      do {
        try setData(from: value, merge: merge, encoder: encoder) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume()
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
  
  func setData<T: Encodable>(
    from value: T,
    mergeFields: [Any],
    encoder: Firestore.Encoder = Firestore.Encoder()
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      do {
        try setData(from: value, mergeFields: mergeFields, encoder: encoder) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume()
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
