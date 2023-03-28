@testable import Graph
import XCTest

final class GraphTests: XCTestCase {
  func parse(_ arguments: [String]? = nil) throws -> TestGraph {
    try TestGraph(graph: Graph.parse(arguments))
  }

  func testFiles() throws {
    let parsed = try parse(["a", "b", "--output", "c"])
    XCTAssertEqual(parsed, .fixture())
  }

  func testFilesWithTitle() throws {
    let parsed = try parse(["--output", "c", "--title", "d", "a", "b"])
    XCTAssertEqual(parsed, .fixture(title: "d"))
  }

  func testFilesWithNode() throws {
    XCTAssertEqual(
      try parse(
        ["--output", "c", "--node", "d", "a", "b"]
      ),
      .fixture(nodes: ["d"])
    )

    XCTAssertEqual(
      try parse(
        ["--output", "c", "--node", "d", "--node", "e", "a", "b"]
      ),
      .fixture(nodes: ["d", "e"])
    )
  }
}

struct TestGraph: Equatable {
  internal init(files: [String], nodes: [String], output: String, title: String? = nil) {
    self.files = files
    self.nodes = nodes
    self.output = output
    self.title = title
  }

  internal init(graph: Graph) {
    self.init(
      files: graph.files,
      nodes: graph.nodes,
      output: graph.output,
      title: graph.title
    )
  }

  var files: [String]
  var nodes: [String]
  var output: String
  var title: String?

  static func fixture(
    files: [String] = ["a", "b"],
    nodes: [String] = [],
    output: String = "c",
    title: String? = nil
  ) -> Self {
    .init(files: files, nodes: nodes, output: output, title: title)
  }
}
