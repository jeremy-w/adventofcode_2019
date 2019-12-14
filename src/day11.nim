# Day 11: The Painting Robot
#
# It reads the color of the panel the robot is on, outputs a color to paint, then a direction to turn and step towards.
# All panels are black initially. The robot is facing up.

import intcode_machine_v2
import sequtils
import sets
import strformat
import sugar

# Inputs to the program
const
  Black = 0
  White = 1
  InitialColor = Black

# Outputs from the program
const
  TurnLeft = 0
  TurnRight = 1

type
  Point = tuple[x, y: int]

  Dir = enum N, S, E, W

  Color = int

  Mark = tuple
    point: Point
    color: Color

  Robot = ref object of RootObj
    brain: Machine
    loc: Point
    dir: Dir
    # Latest mark is at the end.
    trail: seq[Mark]

func colorAt(trail: seq[Mark], point: Point): Color =
  result = InitialColor
  var i = high(trail)
  while i >= low(trail):
    if trail[i].point == point:
      return trail[i].color
    dec i

func paint(r: var Robot, color: Color) =
  r.trail.add (r.loc, color)

func leftDir(dir: Dir): Dir =
  case dir
  of N: W
  of E: N
  of S: E
  of W: S

func rightDir(dir: Dir): Dir =
  case dir
  of N: E
  of E: S
  of S: W
  of W: N

func delta(dir: Dir): Point =
  case dir
  of N: (x: 0, y: 1)
  of S: (x: 0, y: -1)
  of E: (x: 1, y: 0)
  of W: (x: -1, y: 0)

func walk(r: var Robot) =
  let d = r.dir.delta
  r.loc = (r.loc.x + d.x, r.loc.y + d.y)

func turn(r: var Robot, towards: int) =
  case towards
  of TurnLeft:
    r.dir = r.dir.leftDir
  of TurnRight:
    r.dir = r.dir.rightDir
  else:
    doAssert(false, &"Invalid direction to turn: {towards}")

proc makeRobot(name: string = ""): Robot =
  let brain = makeMachine(mem = readFile("input/day11.txt").toProgram, id = name)
  var r = Robot(brain: brain, loc: (0, 0), dir: N, trail: newSeq[Mark]())
  r.brain.onInput = (_: Machine) => r.trail.colorAt(r.loc).Int
  var isColor = true # otherwise is turndir
  r.brain.onOutput = proc(i: Int, _: Machine) =
    if isColor:
      r.trail.add (r.loc, i.int)
    else:
      r.turn(towards = i.int)
      r.walk()
    isColor = not isColor
  return r

proc uniqueLocations(trail: seq[Mark]): int =
  trail.mapIt(it.point).toHashSet.len

echo "Day 11"
# Part 1 puzzle: How many panels does it paint at least once?
# Note it may paint the same panel repeatedly, and it may paint black panels black.
var r = makeRobot("Robi")
r.brain.run()
let part1Answer = r.trail.uniqueLocations
echo "Part 1: Panels painted at least once: ", part1Answer
doAssert part1Answer == 2211
