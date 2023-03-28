import ArgumentParser

struct Graph: ParsableCommand {
  internal init(
    files: [String],
    title: String?,
    nodes: [String],
    output: String
  ) {
    self.files = files
    self.title = title
    self.output = output
    self.nodes = nodes
  }

  @Argument var files: [String]
  @Option var title: String?
  @Option(name: [.customShort("n"), .customLong("node")]) var nodes: [String] = []
  @Option var output: String
}

extension Graph {
  init() {}
}
