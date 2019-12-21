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

echo &"scanning {points.len} points"

while true:
  let machine = makeMachine(prog, onInput = feedNextCoord,
      onOutput = recordResult)
  machine.run()
  if nextIndex > points.high:
    break

let pointsAffectedCnt = toSeq(results.values).sum
echo "points affected: ", pointsAffectedCnt
assert pointsAffectedCnt == 173
