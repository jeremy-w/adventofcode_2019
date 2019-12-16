#[
The arcade cabinet runs Intcode software like the game the Elves sent (your puzzle input). It has a primitive screen capable of drawing square tiles on a grid. The software draws tiles to the screen with output instructions: every three output instructions specify the x position (distance from the left), y position (distance from the top), and tile id. The tile id is interpreted as follows:

    0 is an empty tile. No game object appears in this tile.
    1 is a wall tile. Walls are indestructible barriers.
    2 is a block tile. Blocks can be broken by the ball.
    3 is a horizontal paddle tile. The paddle is indestructible.
    4 is a ball tile. The ball moves diagonally and bounces off objects.

For example, a sequence of output values like 1,2,3,6,5,4 would draw a horizontal paddle tile (1 tile from the left and 2 tiles from the top) and a ball tile (6 tiles from the left and 5 tiles from the top).

Start the game. How many block tiles are on the screen when the game exits?
]#
import intcode_machine_v2
import sequtils
import strformat
import strutils
import sugar
import tables
import terminal

const
  NumRows = 21
  NumCols = 40

type
  TileOutput = enum
    toCol
    toRow
    toId

  TileId = enum
    tiEmpty = (0, " ")
    tiWall = (1, "|")
    tiBlock = (2, "#")
    tiPaddle = (3, "_")
    tiBall = (4, "O")

  Point = tuple[c, r: Int]

  Screen = ref object of RootObj
    disp: Table[Point, TileId]
    next: TileOutput
    score: Int
    accu: Point

func corners(points: openArray[Point]): tuple[min, max: Point] =
  var minP = (c: NumCols.Int, r: NumRows.Int)
  var maxP = (c: 0.Int, r: 0.Int)
  for (c, r) in points:
    minP.c = min(minP.c, c)
    minP.r = min(minP.r, r)
    maxP.c = max(maxP.c, c)
    maxP.r = max(maxP.r, r)
  result.min = minP
  result.max = maxP

func show(s: Screen): string =
  let (_, br) = toSeq(s.disp.keys).corners
  var lines = sequtils.repeat(' '.repeat(br.c + 1), br.r + 1)
  for pt, tile in s.disp:
    lines[pt.r][pt.c] = ($tile)[0]
  lines.add &"\pScore: {s.score}"
  lines.join("\p")

const prog = readFile("input/day13.txt").toProgram

var screen = Screen()
func output(s: Screen, i: Int) =
  case s.next
  of toCol:
    s.accu.c = i
    s.next = toRow
  of toRow:
    s.accu.r = i
    s.next = toId
  of toId:
    if s.accu == (-1.Int, 0.Int):
      s.score = i
    else:
      # debugEcho &"drawing: {s.accu}"
      s.disp[s.accu] = i.TileId
    s.next = toCol

var machine = makeMachine(
  mem = prog,
  onOutput = (i: Int, m: Machine) => screen.output(i))

echo "== Day 13 =="
echo "-- Part 1 --"
machine.run()
let blockTileCount = toSeq(screen.disp.values).count(tiBlock)
echo &"Block tiles left at halt: {blockTileCount}"

let ballTileCount = toSeq(screen.disp.values).count(tiBall)
let paddleTileCount = toSeq(screen.disp.values).count(tiPaddle)
let wallTileCount = toSeq(screen.disp.values).count(tiWall)
echo &"ball {ballTileCount}, paddle {paddleTileCount}, wall {wallTileCount}"

let (minP, maxP) = toSeq(screen.disp.keys).corners
echo &"grid from {minP} to {maxP}"

echo screen.show()

#[
Block tiles left at halt: 242
ball 1, paddle 1, wall 80
grid from (c: 0, r: 0) to (c: 39, r: 20)
]#


echo "\n-- Part 2 --"
# Memory address 0 represents the number of quarters that have been inserted; set it to 2 to play for free.

var playableProg = prog
playableProg[0] = 2.Int

# echo playableProg.toPrettyProgram

# When three output instructions specify X=-1, Y=0, the third output instruction is not a tile; the value instead specifies the new score to show in the segment display.

#[ The software reads the position of the joystick with input instructions:

If the joystick is in the neutral position, provide 0.
If the joystick is tilted to the left, provide -1.
If the joystick is tilted to the right, provide 1. ]#

type
  JoystickPos = enum
    jpLeft = -1.Int
    jpNeutral
    jpRight

# Beat the game by breaking all the blocks. What is your score after the last block is broken?

# Approach:
#
# - Clone the machine
# - Run the game ahead to see where the ball will land next
# - Continue execution by moving the ball to the target location
#
# Need to understand the game mechanics better first, though.
# So probably need to visualize and enable playing by hand.
# Hmm, game is losable if you send the ball on a bounce that exceeds how fast you can reach where it will land. So there are branching choices.

proc askHuman(): JoystickPos =
  while true:
    stdout.write("n = left, e = none, i = right\pMOVE: ")
    case getch():
    of 'n': return jpLeft
    of 'e': return jpNeutral
    of 'i': return jpRight
    else: continue

var outputCounter = 0
var screen2 = Screen()
var machine2 = makeMachine(
  mem = playableProg,
  onInput = (m: Machine) => askHuman().Int,
  onOutput =
  proc(i: Int, m: Machine): void =
    # eraseScreen()
    # setCursorPos(0, 0)
    echo "  out: ", i, "; pc: ", m.ip
    screen2.output(i)
    inc outputCounter
    if outputCounter == 3:
      echo screen2.show()
      outputCounter = 0
)
machine2.run()

echo &"Final score: {screen2.score}"
