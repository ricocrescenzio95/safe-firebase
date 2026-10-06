@preconcurrency import FirebaseFirestore

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension TypedQueryProtocol {
  
  /// An asynchronous sequence of query snapshots.
  var snapshots: TypedQuerySnapshotsSequence<Self> {
    snapshots(includeMetadataChanges: false)
  }
  
  /// Creates an asynchronous sequence of query snapshots.
  ///
  /// - Parameter includeMetadataChanges: Whether metadata-only changes should be emitted.
  /// - Returns: A sequence of query snapshots.
  func snapshots(includeMetadataChanges: Bool) -> TypedQuerySnapshotsSequence<Self> {
    TypedQuerySnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct TypedQuerySnapshotsSequence<Query: TypedQueryProtocol>: AsyncSequence {
  public typealias Element = TypedQuerySnapshot
  public typealias Failure = Error
  public typealias AsyncIterator = Iterator

  let query: Query
  let includeMetadataChanges: Bool

  /// Creates a new sequence for monitoring query snapshots.
  /// - Parameters:
  ///   - query: The `Query` instance to monitor.
  ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
  public init(_ query: Query, includeMetadataChanges: Bool) {
    self.query = query
    self.includeMetadataChanges = includeMetadataChanges
  }

  /// Creates and returns an iterator for this asynchronous sequence.
  /// - Returns: An `Iterator` for `QuerySnapshotsSequence`.
  public func makeAsyncIterator() -> Iterator {
    Iterator(query: query, includeMetadataChanges: includeMetadataChanges)
  }

  /// The asynchronous iterator for `QuerySnapshotsSequence`.
  public struct Iterator: AsyncIteratorProtocol {
    public typealias Element = TypedQuerySnapshot<Query.Model>
    let stream: AsyncThrowingStream<TypedQuerySnapshot<Query.Model>, Error>
    var streamIterator: AsyncThrowingStream<TypedQuerySnapshot<Query.Model>, Error>.Iterator

    /// Initializes the iterator with the provided `Query` instance.
    /// This sets up the `AsyncThrowingStream` and registers the necessary listener.
    /// - Parameters:
    ///   - query: The `Query` instance to monitor.
    ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
    init(query: Query, includeMetadataChanges: Bool) {
      stream = AsyncThrowingStream { continuation in
        let listener = query._query
          .addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
            if let error = error {
              continuation.finish(throwing: error)
            } else if let snapshot = snapshot {
              continuation.yield(.init(snapshot: snapshot))
            }
          }

        continuation.onTermination = { @Sendable _ in
          listener.remove()
        }
      }
      streamIterator = stream.makeAsyncIterator()
    }

    /// Produces the next element in the asynchronous sequence.
    ///
    /// Returns a `QuerySnapshot` value or `nil` if the sequence has terminated.
    /// Throws an error if the underlying listener encounters an issue.
    /// - Returns: An optional `QuerySnapshot` object.
    public mutating func next() async throws -> Element? {
      try await streamIterator.next()
    }
  }
}

@available(*, unavailable)
extension TypedQuerySnapshotsSequence.Iterator: Sendable {}
