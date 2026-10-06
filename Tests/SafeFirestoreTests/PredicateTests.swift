import Foundation
import Testing
@testable import SafeFirestore
import MetaCodable
import FirebaseFirestore

struct PredicateTests {
  @Test
  func predicatesBuildExpectedOperations() {
    let schema = TestUser.schema(path: [])
    
    #expect((schema.age == 21).operation == .equal(21))
    #expect((schema.age != 21).operation == .notEqual(21))
    #expect((schema.age < 21).operation == .less(21))
    #expect((schema.age <= 21).operation == .lessOrEqual(21))
    #expect((schema.age > 21).operation == .greater(21))
    #expect((schema.age >= 21).operation == .greaterOrEqual(21))
    #expect(schema.age.isIn([18, 21]).operation == .in([18, 21]))
    #expect(schema.age.isNotIn([18, 21]).operation == .notIn([18, 21]))
    #expect((schema.optionalAge >= 18).operation == .greaterOrEqual(18))
    #expect(schema.optionalAge.isIn([18, 21]).operation == .in([18, 21]))
    #expect(schema.tags.arrayContains("swift").operation == .arrayContains("swift"))
    #expect(schema.tags.arrayContainsAny(["swift", "ios"]).operation == .arrayContainsAny(["swift", "ios"]))
    #expect(schema.optionalTags.arrayContains("swift").operation == .arrayContains("swift"))
    #expect((schema.notes == ["one", "two"]).operation == .arrayEqual(["one", "two"]))
    #expect((schema.profile.aliases == ["one", "two"]).operation == .arrayEqual(["one", "two"]))
    #expect(schema.profile.aliases.isIn([["one"], ["two"]]).operation == .arrayIn([["one"], ["two"]]))
    #expect((schema.metadata == ["source": "test"]).operation == .mapEqual(["source": "test"]))
  }

  @Test
  func compoundAndOrPredicatesRemainEquatable() {
    let schema = TestUser.schema(path: [])
    let andPredicate = (schema.age >= 18) && (schema.tags.arrayContains("swift"))
    let orPredicate = (schema.nickname == "ada") || (schema.age < 18)
    
    #expect(andPredicate == ((schema.age >= 18) && (schema.tags.arrayContains("swift"))))
    #expect(orPredicate == ((schema.nickname == "ada") || (schema.age < 18)))
  }

  @Test
  func complexSchemaExposesOnlyTheDesignatedOperators() {
    let schema = OperatorMatrixModel.schema(path: [])
    let leaf = OperatorMatrixLeaf(
      score: 7,
      title: "primary",
      labels: ["swift"],
      values: [0.5, 1.0]
    )

    // Scalar and optional scalar schemas support value and range predicates.
    #expect((schema.count == 3).operation == .equal(3))
    #expect((schema.count != 3).operation == .notEqual(3))
    #expect((schema.count < 10).operation == .less(10))
    #expect((schema.count <= 10).operation == .lessOrEqual(10))
    #expect((schema.count > 0).operation == .greater(0))
    #expect((schema.count >= 1).operation == .greaterOrEqual(1))
    #expect(schema.count.isIn([1, 2, 3]).operation == .in([1, 2, 3]))
    #expect(schema.optionalCount.isNotNull.path == ["optionalCount"])
    #expect(schema.optionalCount.isIn([1, 2]).operation == .in([1, 2]))
    #expect(schema.optionalCount.isNull.path == ["optionalCount"])

    // Boolean fields expose the specialized true/false predicates.
    #expect(schema.enabled.makeFilter() != schema.optionalEnabled.isNull.makeFilter())
    #expect((!schema.enabled).path == ["enabled"])

    // Array schemas support equality and array-in predicates.
    #expect((schema.names == ["Ada", "Grace"]).operation == .arrayEqual(["Ada", "Grace"]))
    #expect((schema.names != ["Ada"]).operation == .arrayNotEqual(["Ada"]))
    #expect(schema.names.arrayContains("Ada").operation == .arrayContains("Ada"))
    #expect(schema.names.arrayContainsAny(["Ada", "Grace"]).operation == .arrayContainsAny(["Ada", "Grace"]))
    #expect(schema.names.isIn([["Ada"], ["Grace"]]).operation == .arrayIn([["Ada"], ["Grace"]]))
    #expect((schema.optionalScores == [1, 2]).operation == .arrayEqual([1, 2]))
    #expect(schema.optionalScores.arrayContains(1).operation == .arrayContains(1))
    #expect(schema.optionalScores.isNotNull.path == ["optionalScores"])

    // Set schemas support contains predicates, but are still addressed as one field.
    #expect(schema.flags.arrayContains("admin").operation == .arrayContains("admin"))
    #expect(schema.flags.arrayContainsAny(["admin", "editor"]).operation == .arrayContainsAny(["admin", "editor"]))
    #expect(schema.optionalFlags.arrayContains("admin").operation == .arrayContains("admin"))

    // Map schemas support map equality and typed traversal into their values.
    #expect((schema.mapValues == ["a": 1]).operation == .mapEqual(["a": 1]))
    #expect((schema.mapArrays["numbers"] == [1, 2]).operation == .arrayEqual([1, 2]))
    #expect(schema.mapSets["tags"].arrayContains("swift").path == ["mapSets", "tags"])
    #expect((schema.nested["first"]["second"]["third"] == 7).path == ["nested", "first", "second", "third"])
    #expect(schema.optionalMap.isNull.path == ["optionalMap"])

    // Non-optional and optional nested models retain their own scalar schemas.
    #expect((schema.leaf.score >= 5).path == ["leaf", "score"])
    #expect((schema.optionalLeaf.title == "primary").path == ["optionalLeaf", "title"])
    #expect(schema.optionalLeaf.isNull.path == ["optionalLeaf"])

    // Nested models work as array and set elements as well.
    #expect((schema.leafArray == [leaf]).operation == .arrayEqual([leaf]))
    #expect((schema.optionalLeafArray == [leaf]).operation == .arrayEqual([leaf]))
    #expect(schema.leafSet.arrayContains(leaf).path == ["leafSet"])
    #expect(schema.optionalLeafSet.arrayContains(leaf).path == ["optionalLeafSet"])

    // Maps preserve the nested model schema, including optional map values.
    #expect((schema.leaves["a"].score == 7).path == ["leaves", "a", "score"])
    #expect(schema.optionalLeaves.isNull.path == ["optionalLeaves"])
  }

  @Test
  func predicateExpressionsMaterializeEveryOperatorFamily() {
    let schema = OperatorMatrixModel.schema(path: [])
    
    _ = (schema.count == 1).makeFilter()
    _ = (schema.count != 1).makeFilter()
    _ = (schema.count < 10).makeFilter()
    _ = (schema.count <= 10).makeFilter()
    _ = (schema.count > 0).makeFilter()
    _ = (schema.count >= 0).makeFilter()
    _ = schema.count.isIn([1, 2]).makeFilter()
    _ = schema.count.isNotIn([3, 4]).makeFilter()
    
    _ = (schema.names == ["Ada"]).makeFilter()
    _ = (schema.names != ["Grace"]).makeFilter()
    _ = schema.names.arrayContains("Ada").makeFilter()
    _ = schema.names.arrayContainsAny(["Ada", "Grace"]).makeFilter()
    _ = schema.names.isIn([["Ada"], ["Grace"]]).makeFilter()
    _ = schema.names.isNotIn([["Unknown"]]).makeFilter()
    
    _ = (schema.mapValues == ["count": 1]).makeFilter()
    _ = (schema.mapValues != ["count": 2]).makeFilter()
    _ = schema.flags.arrayContains("admin").makeFilter()
    _ = schema.optionalFlags.arrayContainsAny(["admin", "editor"]).makeFilter()
    
    _ = schema.enabled.makeFilter()
    _ = (!schema.enabled).makeFilter()
    _ = schema.optionalCount.isNull.makeFilter()
    _ = schema.optionalCount.isNotNull.makeFilter()
    
    let compound = (schema.count >= 18) && (schema.enabled || !schema.enabled)
    _ = compound.makeFilter()
  }
}
