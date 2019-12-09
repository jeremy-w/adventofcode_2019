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

proc abs(p: Point): Point =
  (x: abs(p.x), y: abs(p.y))

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
  let least = points.sortedByIt(it.abs)[0]
  let md = least.len
  result = (p: least, md: md)

when defined(test):
  doAssert("R8,U5,L5,D3")

when isMainModule:
  let input = open("./input/day3.txt")
  let wire1 = input.readLine().toWireProgram
  let wire2 = input.readLine().toWireProgram
  echo ("wire1:", wire1)
  let intersections = wireIntersections(wire1, wire2).toSeq
  let closest = intersections.closestToCore
  echo fmt"least: {closest.p}, manhattanDistnace: {closest.md}"
