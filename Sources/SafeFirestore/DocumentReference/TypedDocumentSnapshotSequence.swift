@preconcurrency import FirebaseFirestore

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension TypedDocumentReference {
  /// A throwing asynchronous sequence of document snapshots.
  ///
  /// This stream emits a new ``TypedDocumentSnapshot`` every time the underlying data changes.
  /// If the underlying listener reports an error, the error is thrown and the sequence terminates.
  /// Use ``nonThrowingSnapshots`` when an error should be emitted as a `Result` while the
  /// listener remains active.
  var snapshots: ThrowingDocumentSnapshotsSequence {
    snapshots(includeMetadataChanges: false)
  }

  /// Creates a throwing asynchronous sequence of document snapshots.
  ///
  /// An error from the underlying listener terminates the sequence after it is thrown.
  /// - Parameter includeMetadataChanges: Whether to receive events for metadata-only changes.
  /// - Returns: A ``TypedDocumentReference/ThrowingDocumentSnapshotsSequence``.
  func snapshots(includeMetadataChanges: Bool) -> ThrowingDocumentSnapshotsSequence {
    ThrowingDocumentSnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }

  /// An `AsyncSequence` that emits ``TypedDocumentSnapshot`` values whenever the document data changes.
  ///
  /// This struct is the concrete type returned by the ``TypedDocumentReference/snapshots`` property.
  struct ThrowingDocumentSnapshotsSequence: AsyncSequence, Sendable {
    public typealias Element = TypedDocumentSnapshot
    public typealias Failure = Error
    public typealias AsyncIterator = Iterator

    let documentReference: TypedDocumentReference
    let includeMetadataChanges: Bool

    /// Creates a new sequence for monitoring document snapshots.
    /// - Parameters:
    ///   - documentReference: The ``TypedDocumentReference`` instance to monitor.
    ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
    public init(_ documentReference: TypedDocumentReference, includeMetadataChanges: Bool) {
      self.documentReference = documentReference
      self.includeMetadataChanges = includeMetadataChanges
    }

    /// Creates and returns an iterator for this asynchronous sequence.
    /// - Returns: An `Iterator` for ``TypedDocumentReference/DocumentSnapshotsSequence``.
    public func makeAsyncIterator() -> Iterator {
      Iterator(documentReference: documentReference, includeMetadataChanges: includeMetadataChanges)
    }

    /// The asynchronous iterator for ``TypedDocumentReference/DocumentSnapshotsSequence``.
    public struct Iterator: AsyncIteratorProtocol {
      public typealias Element = TypedDocumentSnapshot<Model>
      let stream: AsyncThrowingStream<Element, Error>
      var streamIterator: AsyncThrowingStream<Element, Error>.Iterator

      /// Initializes the iterator with the provided ``TypedDocumentReference`` instance.
      /// This sets up the `AsyncThrowingStream` and registers the necessary listener.
      /// - Parameters:
      ///   - documentReference: The ``TypedDocumentReference`` instance to monitor.
      ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
      init(documentReference: TypedDocumentReference, includeMetadataChanges: Bool) {
        stream = AsyncThrowingStream { continuation in
          let listener = documentReference.documentReference
            .addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
              if let error = error {
                continuation.finish(throwing: error)
              } else if let snapshot = snapshot {
                continuation.yield(.init(_documentSnapshot: snapshot))
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
      /// Returns a ``TypedDocumentSnapshot`` value or `nil` if the sequence has terminated.
      /// Throws an error if the underlying listener encounters an issue.
      /// - Returns: An optional `DocumentSnapshot` object.
      public mutating func next() async throws -> Element? {
        try await streamIterator.next()
      }
      
      public mutating func next(isolation actor: isolated (any Actor)?) async throws -> Element? {
        try await streamIterator.next(isolation: actor)
      }
    }
  }
}

@available(*, unavailable)
extension TypedDocumentReference.ThrowingDocumentSnapshotsSequence.Iterator: Sendable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension TypedDocumentReference {
  /// A non-throwing asynchronous sequence of document snapshots.
  ///
  /// This stream emits a `Result` for every listener event. A listener error is emitted as
  /// `Result.failure` and does not terminate the sequence; subsequent snapshot events can
  /// still be received. Use ``snapshots`` when an error should terminate iteration.
  var nonThrowingSnapshots: DocumentSnapshotsSequence {
    nonThrowingSnapshots(includeMetadataChanges: false)
  }
  
  /// Creates a non-throwing asynchronous sequence of document snapshots.
  ///
  /// Errors are delivered as `Result` values and do not close the stream.
  /// - Parameter includeMetadataChanges: Whether to receive events for metadata-only changes.
  /// - Returns: A ``TypedDocumentReference/DocumentSnapshotsSequence`` whose elements are
  ///   `Result` values.
  func nonThrowingSnapshots(includeMetadataChanges: Bool) -> DocumentSnapshotsSequence {
    DocumentSnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }
  
  /// An `AsyncSequence` that emits `Result` values containing ``TypedDocumentSnapshot`` values
  /// or listener errors.
  ///
  /// This struct is the concrete type returned by the ``TypedDocumentReference/nonThrowingSnapshots`` property.
  /// Unlike ``ThrowingDocumentSnapshotsSequence``, an error is yielded as a value and does not
  /// finish the listener stream.
  struct DocumentSnapshotsSequence: AsyncSequence, Sendable {
    public typealias Element = Result<TypedDocumentSnapshot<Model>, Error>
    public typealias AsyncIterator = Iterator

    let documentReference: TypedDocumentReference
    let includeMetadataChanges: Bool

    /// Creates a new sequence for monitoring document snapshots.
    /// - Parameters:
    ///   - documentReference: The ``TypedDocumentReference`` instance to monitor.
    ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
    public init(_ documentReference: TypedDocumentReference, includeMetadataChanges: Bool) {
      self.documentReference = documentReference
      self.includeMetadataChanges = includeMetadataChanges
    }

    /// Creates and returns an iterator for this asynchronous sequence.
    /// - Returns: An `Iterator` for ``TypedDocumentReference/DocumentSnapshotsSequence``.
    public func makeAsyncIterator() -> Iterator {
      Iterator(documentReference: documentReference, includeMetadataChanges: includeMetadataChanges)
    }

    /// The asynchronous iterator for ``TypedDocumentReference/DocumentSnapshotsSequence``.
    public struct Iterator: AsyncIteratorProtocol {
      public typealias Element = Result<TypedDocumentSnapshot<Model>, Error>
      let stream: AsyncStream<Element>
      var streamIterator: AsyncStream<Element>.Iterator

      /// Initializes the iterator with the provided ``TypedDocumentReference`` instance.
      /// This sets up an `AsyncStream` and registers the necessary listener.
      /// Listener errors are yielded as `Result.failure` values, so they do not finish the stream.
      /// - Parameters:
      ///   - documentReference: The ``TypedDocumentReference`` instance to monitor.
      ///   - includeMetadataChanges: Whether to receive events for metadata-only changes.
      init(documentReference: TypedDocumentReference, includeMetadataChanges: Bool) {
        stream = AsyncStream { continuation in
          let listener = documentReference.documentReference
            .addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
              if let error = error {
                continuation.yield(.failure(error))
              } else if let snapshot = snapshot {
                continuation.yield(.success(.init(_documentSnapshot: snapshot)))
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
      /// Returns a `Result` containing a ``TypedDocumentSnapshot`` or an error, or `nil` if
      /// the sequence has terminated. Errors do not terminate this sequence; they are values.
      /// - Returns: The next result, or `nil` after the listener has been cancelled.
      public mutating func next() async -> Element? {
        await streamIterator.next()
      }
      
      public mutating func next(isolation actor: isolated (any Actor)?) async -> Element? {
        await streamIterator.next(isolation: actor)
      }
    }
  }
}
