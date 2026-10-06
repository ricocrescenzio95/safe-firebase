import FirebaseFunctions
import FirebaseSharedSwift
import Foundation
import FirebaseFirestore

/// An empty Codable payload used when a callable function has no request or response body.
public struct EmptyRequestResponse: Sendable, Codable, Hashable {}

struct TypedCallable<Request: Encodable, Response: Decodable> {
  let callable: Callable<Request, Response>
  
  func call(_ data: Request) async throws(NetworkCallError) -> Response {
    do {
      return try await callable.call(data)
    } catch {
      throw NetworkCallError.fromError(error)
    }
  }
  
  func call(_ data: Request) async throws(NetworkCallError) where Response == EmptyRequestResponse {
    do {
      _ = try await callable.call(data)
    } catch {
      throw NetworkCallError.fromError(error)
    }
  }
  
  func call() async throws(NetworkCallError) -> Response where Request == EmptyRequestResponse {
    do {
      return try await callable.call(EmptyRequestResponse())
    } catch {
      throw NetworkCallError.fromError(error)
    }
  }
  
  func call() async throws(NetworkCallError) where Request == EmptyRequestResponse, Response == EmptyRequestResponse {
    do {
      _ =  try await callable.call(EmptyRequestResponse())
    } catch {
      throw NetworkCallError.fromError(error)
    }
  }
}

extension Functions {
  func typedCallable<Request: Encodable, Response: Decodable>(
    _ name: String,
    requestAs: Request.Type = Request.self,
    responseAs: Response.Type = Response.self,
    encoder: FirebaseDataEncoder = FirebaseDataEncoder(),
    decoder: FirebaseDataDecoder = FirebaseDataDecoder()
  ) -> TypedCallable<Request, Response> {
    TypedCallable(
      callable: httpsCallable(name, requestAs: Request.self, responseAs: Response.self, encoder: encoder, decoder: decoder)
    )
  }
  
  func typedCallable<Request: Encodable>(
    _ name: String,
    requestAs: Request.Type = Request.self,
    encoder: FirebaseDataEncoder = FirebaseDataEncoder(),
    decoder: FirebaseDataDecoder = FirebaseDataDecoder()
  ) -> TypedCallable<Request, EmptyRequestResponse> {
    TypedCallable(
      callable: httpsCallable(name, requestAs: Request.self, responseAs: EmptyRequestResponse.self, encoder: encoder, decoder: decoder)
    )
  }
}

extension FirebaseDataDecoder {
  private struct FirestoreTimestamp: Decodable {
    var _seconds: Int64
    var _nanoseconds: Int32
    
    func dateValue() -> Date {
      Timestamp(seconds: _seconds, nanoseconds: _nanoseconds).dateValue()
    }
  }
  static func timestampDate() -> FirebaseDataDecoder {
    let decoder = FirebaseDataDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(FirestoreTimestamp.self)
      return value.dateValue()
    }
    return decoder
  }
}
