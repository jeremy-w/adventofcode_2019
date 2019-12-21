# scan 0..49,0..49
# input x,y as 2 separate inputs
# 0 output is off, 1 is on
# sum the 1s
import intcode_machine_v2
import math
import sequtils
import strformat
import tables

type Point = tuple[x: Int, y: Int]

let prog = readFile("input/day19.txt").toProgram
echo prog.toPrettyProgram

var points: seq[Point]
for y in 0..49:
  for x in 0..49:
    points.add (x: x.Int, y: y.Int)

var nextIsX = true
var nextIndex = 0

var scannedPoint = points[nextIndex]
var results = initTable[Point, Int]()

proc feedNextCoord(m: Machine): Int =
  if nextIsX:
    scannedPoint = points[nextIndex]
    result = scannedPoint.x
  else:
    result = scannedPoint.y
    inc nextIndex
  nextIsX = not nextIsX

var lastY = 0.Int
proc recordResult(i: Int, m: Machine) =
  results[scannedPoint] = i
  if scannedPoint.y > lastY:
    echo ""
  lastY = scannedPoint.y
  stdout.write(if i > 0: "#" else: ".")

# echo &"scanning {points.len} points"

# while true:
#   let machine = makeMachine(prog, onInput = feedNextCoord,
#       onOutput = recordResult)
#   machine.run()
#   if nextIndex > points.high:
#     break

# let pointsAffectedCnt = toSeq(results.values).sum
# echo "points affected: ", pointsAffectedCnt
# assert pointsAffectedCnt == 173

#[
  Part 2:
    Find the 100x100 square closest to the emitter that fits entirely within the tractor beam; within that square, find the point closest to the emitter.
    What value do you get if you take that point's X coordinate, multiply it by 10000, then add the point's Y coordinate?
  ]#

proc scan(point: Point): Int =
  var sendX = true
  var theAnswer = 0.Int
  let machine = makeMachine(prog, onInput = proc (m: Machine): Int =
    result = if sendX: point.x else: point.y
    sendX = not sendX,
    onOutput = proc(i: Int, m: Machine) =
      theAnswer = i)
  machine.run
  return theAnswer

proc scanRow(y: int, verbose = false): Slice[Int] =
  var x = 0.Int
  var firstX = -1.Int
  var lastX = -1.Int
  while scan((x: x, y: y.Int)) == 0:
    if verbose: stdout.write('.')
    inc x
  firstX = x
  while scan((x: x, y: y.Int)) == 1:
    if verbose: stdout.write('#')
    lastX = x
    inc x
  if verbose: stdout.write("\p")
  return firstX..lastX

assert scanRow(11) == 7.Int .. 7.Int
assert scanRow(12) == 7.Int .. 8.Int

proc isCovered(ul: Point, br: Point): bool =
  result = true
  for x in ul.x .. br.x:
    for y in ul.y .. br.y:
      if scan((x, y)) == 0:
        return false

proc isCovered(ul: Point): bool =
  isCovered(ul, (ul.x + 99, ul.y + 99))

var y = 705
while true:
  echo &"row {y}"
  let covered = scanRow(y, true)
  let pt = (covered.a, y.Int)
  if isCovered(pt):
    echo "bingo! ", pt
    break
  inc y
# first row of width 100 is: 705
# it covers: 393 .. 492

proc scanCol(p: Point): Slice[Int] =
  var firstY = -1.Int
  var lastY = -1.Int
  var y = p.y
  if scan(p) == 1:
    firstY = y
    dec y
    while scan((x: p.x, y: y)) == 1:
      firstY = y
      dec y
    y = p.y
  else:
    while scan((x: p.x, y: y)) == 1:
      inc y
    firstY = y
  while scan((x: p.x, y: y)) == 1:
    lastY = y
    inc y
  return firstY..lastY

assert scanCol((x: 4.Int, y: 6.Int)) == 6.Int .. 7.Int

# for x in 393.Int .. 492.Int:
#   let p = (x: x, y: y.Int)
#   let covered = scanCol(p)
#   echo &"{p} covers {covered.len}: {covered}"
# (x: 393, y: 705) covers 143: 563 .. 705

let hit = (x: 393.Int, y: 705.Int)
echo &"hit: {hit}, answer: {hit.x * 10000 + hit.y}"
# That's not the right answer; your answer 3930705 is too low.
# Oh, I bet the width on the far side is bogus.
# y=705 is the first time it's 100 wide.
# It may not be 100 wide for 100 rows, and the >100-height region may not cover a square.

# var p = hit
# while not isCovered(p):
#   inc p.x
#   inc p.y
# echo "first solid hit:", p
