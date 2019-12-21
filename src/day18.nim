# How many steps is the shortest path that collects all of the keys?
# input is map.
# keys are lowercase, doors uppercase, moves are only NESW, @ is you, . is floor, # is wall
import algorithm
import sequtils
import strformat
import strutils
import deques

type
  Move = enum
    mvN
    mvS
    mvE
    mvW

  SolutionTree = ref object of RootObj
    key: char
    keysHeld: string
    before: seq[string]
    moves: seq[Move]
    after: seq[string]
    next: seq[SolutionTree]

const
  You = '@'
  Floor = '.'
  Wall = '#'

func isKey(c: char): bool = c.isLowerAscii
func isDoor(c: char): bool = c.isUpperAscii
func toMap(puzzle: string): seq[string] =
  puzzle
  .splitLines
  .filterIt (it.contains(Floor) or it.contains(Wall))

func reachableKeys(map: seq[string], withKeys: string): string =
  discard

func findShortestPath(through: seq[string], withKeys: string): seq[Move] =
  discard

func walkToKey(node: SolutionTree) =
  let target = node.key
  node.moves = findShortestPath(through = node.before, withKeys = node.keysHeld)
  node.after = node.before.mapIt it.multireplace {$target: $You, $You: $Floor}

func shortestPathToAllKeys(puzzle: string): tuple[moves: seq[Move],
    keyOrder: string] =
  var map = puzzle.toMap
  var root = SolutionTree(key: 'R', before: map)
  var queue = initDeque[SolutionTree]()
  queue.addLast root
  # breadth-first search
  while queue.len > 0:
    var node = queue.popFirst
    if node.key != 'R':
      node.walkToKey()
    let keys = node.after.reachableKeys(withKeys = node.keysHeld)
    for key in keys:
      let choice = SolutionTree(key: key, before: node.after)
      queue.addLast choice
      node.next.add choice

let ex1 = shortestPathToAllKeys(
"""#########
#b.A.@.a#
#########""")

assert ex1.moves.len == 8, &"got: {ex1.moves.len}, {ex1}"
assert ex1.keyOrder == "ab", &"got: {ex1.moves.len}, {ex1}"

const puzzle = readFile("input/day18.txt").toMap

let doors = puzzle
  .mapIt(it.filterIt it.isDoor)
  .concat
  .sorted
  .join("")
# 26 doors: ABCDEFGHIJKLMNOPQRSTUVWXYZ
echo &"{doors.len} doors: {doors}"
