//
//  File.swift
//
//
//  Created by Yu Yu on 2023/3/28.
//

import Foundation

let graph = try Graph.parse()

try gen(roots: graph.nodes, files: graph.files)
