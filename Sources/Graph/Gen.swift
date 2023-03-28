import Foundation

public let replaceMap = [
  "AnyCodable-FlightSchool": "AnyCodable",
]

let forcedInGroup: [String: String] = [
  "AWSAPIGateway": "AWS",
  "CocoaAsyncSocket": "CocoaAsyncSocket",
]

public struct SplitResult: Equatable {
  public init(key: String, rest: String) {
    self.key = key
    self.rest = rest
  }

  public var key: String
  public var rest: String
}

public func groupToSubgraph(_ group: [String: [String]]) -> [String] {
  var result: [String] = []
  for var key in group.keys.sorted() {
    let list = group[key]!
    if list.contains(key) {
      key += "-Group"
    }
    let sub =
      """
        subgraph \(key)
      \(list.map { "    " + $0 }.joined(separator: "\n"))
        end
      """
    result.append(sub)
  }
  return result
}

public func listToGroup(
  _ list: [String],
  root: [String],
  replaceMap: [String: String] = [:],
  forcedInGroup: [String: String] = [:]
) -> [String: [String]] {
  var list = list
  for (key, value) in replaceMap {
    if let index = list.firstIndex(of: key) {
      list[index] = value
    }
  }
  for appName in root {
    if let index = list.firstIndex(of: appName) {
      list.remove(at: index)
    }
  }
  list = Array(Set(list))
  var group = Dictionary(grouping: list.sorted()) { ele in
    let key = split(ele).key
    return key
  }
  for key in group.keys.sorted() {
    var values = group[key]!
    let origin = values
    group[key] = nil
    var commaPrefix = values.removeFirst()
    for value in values {
      commaPrefix = commaPrefix.commonPrefix(with: value)
    }
    if commaPrefix.count > 1 {
      group[commaPrefix] = origin
    } else {
      group["other", default: []].append(contentsOf: origin)
    }
  }

  for (key, value) in group where value.count == 1 {
    group[key] = nil
    if root.contains(value[0]) { continue }
    group["other", default: []].append(contentsOf: value)
  }
  for appName in root {
    if let list = group[appName] {
      group[appName] = nil
      group[appName + "-group"] = list
    }
  }
  var others = group["other"] ?? []

  for index in others.indices.reversed() {
    let other = others[index]
    if let groupKey = forcedInGroup[other] {
      group[groupKey, default: []].append(other)
      others.remove(at: index)
    }
  }

  others.sort()
  if others.isEmpty == false {
    group["other"] = others
  }

  return group
}

public func token(_ str: String) -> [String] {
  var result: [String] = []
  var temp: [String] = []
  for c in str {
    if c.isUppercase {
      if temp.allSatisfy({ $0.first!.isUppercase }) == false {
        result.append(temp.joined())
        temp.removeAll()
      }
    }
    if c == "/" {
      result.append(temp.joined())
      temp.removeAll()
      continue
    }
    temp.append(c.description)
  }

  if temp.isEmpty == false {
    result.append(temp.joined())
  }
  return result
}

public func split(_ raw: String) -> SplitResult {
  if raw.allSatisfy(\.isUppercase) {
    return .init(key: raw, rest: "")
  }
  if raw.contains("/") == false {
    var allCap = raw[...].prefix { $0.isUppercase }
    if allCap.count > 1 {
      var r = raw[...]
      allCap.removeLast()
      r.removeFirst(allCap.count)
      return .init(key: allCap.description, rest: r[...].description)
    }
  }
  if raw.contains("/") {
    let splited = raw.components(separatedBy: "/")
    if splited.count > 1 {
      let s = split(splited[0])
      let key = s.key
      return .init(key: key, rest: s.rest + "/" + splited[1...].joined())
    }
  }

  var reachUppercase = false
  var secondUppercase = false
  var key = ""
  var rest = ""
  for char in raw {
    if reachUppercase == false, char.isUppercase {
      key.append(char.description)
      reachUppercase = true
    } else if reachUppercase {
      if char.isUppercase {
        secondUppercase = true
        rest.append(char.description)
      } else {
        if secondUppercase {
          rest.append(char.description)
        } else {
          key.append(char.description)
        }
      }
    } else if reachUppercase == false, secondUppercase == false {
      key.append(char.description)
    } else {
      rest.append(char.description)
    }
  }
  return .init(key: key, rest: rest)
}

let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let files = CommandLine.arguments[1...]
  .map { currentDirectory.appendingPathComponent($0) }

struct Edge: Decodable, Hashable {
  var a, b: String
}

var allEdges: [Edge] = []

func gen(
  roots: [String],
  files: [String],
  contentsOf: (String) throws -> Data = {
    try Data(contentsOf: currentDirectory.appendingPathComponent($0))
  }
) throws {
  for file in files {
    let edges = try JSONDecoder().decode(
      [Edge].self,
      from: contentsOf(file)
    )
    allEdges.append(contentsOf: edges)
  }

  allEdges = allEdges.map { edge in
    var edge = edge
    if let replace = replaceMap[edge.a] {
      edge.a = replace
    }
    if let replace = replaceMap[edge.b] {
      edge.b = replace
    }
    return edge
  }

  allEdges = Array(Set(allEdges))
  let allDots = Array(Set(allEdges.flatMap { [$0.a, $0.b] })).sorted()
  let output = currentDirectory.appendingPathComponent("edges.mmd")
  let group = listToGroup(
    allDots, root: roots,
    replaceMap: replaceMap,
    forcedInGroup: forcedInGroup
  )
  let subGraphs = groupToSubgraph(group).joined(separator: "\n\n")
  let edges = allEdges
    .sorted {
      ($0.a.lowercased(), $0.b.lowercased()) < ($1.a.lowercased(), $1.b.lowercased())
    }
    .map { edge in
      "\(edge.a)  --> \(edge.b)"
    }
    .joined(separator: "\n")
  try (
    "flowchart LR\n" + subGraphs + "\n\n" + edges + "\n"
  )
  .data(using: .utf8)!
  .write(to: output, options: [])
}
