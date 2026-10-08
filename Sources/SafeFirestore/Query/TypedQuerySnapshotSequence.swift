@preconcurrency import FirebaseFirestore

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension TypedQueryProtocol {
  
  /// A throwing asynchronous sequence of query snapshots.
  /// Listener errors are thrown and terminate the sequence. Use ``nonThrowingSnapshots`` to
  /// receive errors as `Result` values without closing the stream.
  var snapshots: TypedThrowingQuerySnapshotsSequence<Self> {
    snapshots(includeMetadataChanges: false)
  }
  
  /// A non-throwing asynchronous sequence of query snapshots.
  /// Listener errors are yielded as `Result.failure` values and do not terminate the sequence.
  var nonThrowingSnapshots: TypedQuerySnapshotsSequence<Self> {
    nonThrowingSnapshots(includeMetadataChanges: false)
  }
  
  /// Creates a throwing asynchronous sequence of query snapshots.
  /// An error terminates the sequence after it is thrown.
  /// - Parameter includeMetadataChanges: Whether metadata-only changes should be emitted.
  /// - Returns: A throwing sequence of query snapshots.
  func snapshots(includeMetadataChanges: Bool) -> TypedThrowingQuerySnapshotsSequence<Self> {
    TypedThrowingQuerySnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }
  
  /// Creates a non-throwing asynchronous sequence of query snapshots.
  /// Errors are emitted as `Result.failure` values, so the listener stream remains active.
  /// - Parameter includeMetadataChanges: Whether metadata-only changes should be emitted.
  /// - Returns: A sequence whose elements are `Result` values.
  func nonThrowingSnapshots(includeMetadataChanges: Bool) -> TypedQuerySnapshotsSequence<Self> {
    TypedQuerySnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct TypedThrowingQuerySnapshotsSequence<Query: TypedQueryProtocol>: AsyncSequence, Sendable {
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

  /// The asynchronous iterator for the throwing query snapshot sequence.
  public struct Iterator: AsyncIteratorProtocol {
    public typealias Element = TypedQuerySnapshot<Query.Model>
    let stream: AsyncThrowingStream<Element, Error>
    var streamIterator: AsyncThrowingStream<Element, Error>.Iterator

    /// Initializes the iterator with the provided `Query` instance.
    /// This sets up an `AsyncThrowingStream`; a listener error finishes the stream.
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
extension TypedThrowingQuerySnapshotsSequence.Iterator: Sendable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct TypedQuerySnapshotsSequence<Query: TypedQueryProtocol>: AsyncSequence, Sendable {
  /// Each event is either a typed snapshot or the error reported by the listener.
  public typealias Element = Result<TypedQuerySnapshot<Query.Model>, Error>
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
    public typealias Element = Result<TypedQuerySnapshot<Query.Model>, Error>
    let stream: AsyncStream<Element>
    var streamIterator: AsyncStream<Element>.Iterator

    /// Initializes the iterator with the provided `Query` instance.
    /// This sets up an `AsyncStream`; listener errors are yielded as `Result.failure` values and do not finish the stream.
    /// - Parameters:
    ///   - query: The `Query` instance to monitor.
    ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
    init(query: Query, includeMetadataChanges: Bool) {
      stream = AsyncStream { continuation in
        let listener = query._query
          .addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
            if let error = error {
              continuation.yield(.failure(error))
            } else if let snapshot = snapshot {
              continuation.yield(.success(.init(snapshot: snapshot)))
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
    /// Returns a `Result` containing a `QuerySnapshot` or an error, or `nil` after cancellation.
    /// Errors are values and do not terminate this sequence.
    /// - Returns: The next result, or `nil` after the listener has been cancelled.
    public mutating func next() async -> Element? {
      await streamIterator.next()
    }
    
    public mutating func next(isolation actor: isolated (any Actor)?) async -> Element? {
      await streamIterator.next(isolation: actor)
    }
  }
}

@available(*, unavailable)
extension TypedQuerySnapshotsSequence.Iterator: Sendable {}
