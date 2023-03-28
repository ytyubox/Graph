//
//  File.swift
//
//
//  Created by Yu Yu on 2023/3/28.
//

import Foundation
let graph: Graph
do {
  graph = try Graph.parse()
} catch {
  print(Graph.message(for: error))
  exit(1)
}
try gen(roots: graph.nodes, files: graph.files)
