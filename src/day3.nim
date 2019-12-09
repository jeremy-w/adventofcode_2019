import algorithm
import sequtils
import sets
import strformat
import strutils

type
  Point = tuple
    x: int
    y: int

  WireOp = enum
    # Huh, apparently they must be listed in ordinal order?
    woDown = (ord('D'), "D")
    woLeft = (ord('L'), "L")
    woRight = (ord('R'), "R")
    woUp = (ord('U'), "U")

  WireCmd = tuple
    op: WireOp
    d: int

  WireProgram =
    seq[WireCmd]

proc len(p: Point): int =
  p.x.abs + p.y.abs

proc toWireProgram(line: string): WireProgram =
  line.split(',').mapIt((op: it[0].WireOp, d: parseInt(it[1..^1])))

proc pointsIn(prog: WireProgram): seq[Point] =
  result = @[]
  var p: Point = (0, 0)
  for cmd in prog:
    var i = 0
    while i < cmd.d:
      i += 1
      case cmd.op
      of woDown:
        p.y -= 1
      of woLeft:
        p.x -= 1
      of woRight:
        p.x += 1
      of woUp:
        p.y += 1
      result.add p

proc wireIntersections(wire1: WireProgram, wire2: WireProgram): HashSet[Point] =
  let path1 = pointsIn(wire1).toHashSet
  let path2 = pointsIn(wire2).toHashSet
  result = (path1 * path2)

proc closestToCore(points: seq[Point]): tuple[p: Point, md: int] =
  let least = points.sortedByIt(it.len)[0]
  let md = least.len
  result = (p: least, md: md)

type Part2Result = tuple[p: Point, w1: int, w2: int]

proc shortestWireLengths(wire1: WireProgram, wire2: WireProgram):
    seq[Part2Result] =
  let path1 = pointsIn(wire1)
  let path2 = pointsIn(wire2)
  result = (path1.toHashSet * path2.toHashSet)
    .toSeq
    .map(proc(it: Point): Part2Result =
      (p: it, w1: path1.find(it), w2: path2.find(it)))
    .sortedByIt(it.w1 + it.w2)

when defined(test):
  proc wireIntersections(wire1: string, wire2: string): HashSet[Point] =
    wireIntersections(wire1.toWireProgram, wire2.toWireProgram)

  const simple1 = "R8,U5,L5,D3"
  const simple2 = "U7,R6,D4,L4"
  let simpleExpectedIntersections = toHashSet([(3, 3),
  (6, 5)])
  let simpleIntersections = wireIntersections(simple1, simple2)
  doAssert simpleIntersections == simpleExpectedIntersections, fmt"got {simpleIntersections}, expected {simpleExpectedIntersections} for {simple1} & {simple2}"
  echo "tests passed"
  quit(QuitSuccess)

when isMainModule:
  let input = open("./input/day3.txt")
  let wire1 = input.readLine().toWireProgram
  let wire2 = input.readLine().toWireProgram
  let intersections = wireIntersections(wire1, wire2).toSeq
  let closest = intersections.closestToCore
  echo fmt"least: {closest.p}, manhattanDistance: {closest.md}"

  let shortest = shortestWireLengths(wire1, wire2)[0]
  echo fmt"{shortest} gives total steps of: {shortest.w1 + shortest.w2}"
