@preconcurrency import FirebaseFirestore

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension TypedDocumentReference {
  /// An asynchronous sequence of document snapshots.
  ///
  /// This stream emits a new ``TypedDocumentSnapshot`` every time the underlying data changes.
  var snapshots: DocumentSnapshotsSequence {
    snapshots(includeMetadataChanges: false)
  }

  /// An asynchronous sequence of document snapshots.
  ///
  /// - Parameter includeMetadataChanges: Whether to receive events for metadata-only changes.
  /// - Returns: A ``TypedDocumentReference/DocumentSnapshotsSequence`` of ``TypedDocumentSnapshot`` events.
  func snapshots(includeMetadataChanges: Bool) -> DocumentSnapshotsSequence {
    DocumentSnapshotsSequence(self, includeMetadataChanges: includeMetadataChanges)
  }

  /// An `AsyncSequence` that emits ``TypedDocumentSnapshot`` values whenever the document data changes.
  ///
  /// This struct is the concrete type returned by the ``TypedDocumentReference/snapshots`` property.
  struct DocumentSnapshotsSequence: AsyncSequence {
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
    }
  }
}

@available(*, unavailable)
extension TypedDocumentReference.DocumentSnapshotsSequence.Iterator: Sendable {}
