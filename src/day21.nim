#[
Program a springdroid to successfully jump all the holes in the hull.
Its last output will be the amount of hull damage. This will be outside the ASCII range.
]#
import intcode_machine_v2
import streams
import strutils
import strformat
import sugar

## it can only remember at most 15 springscript instructions.
const MaxCmdCnt = 15

## When you have finished entering your program, provide the command WALK followed by a newline to instruct the springdroid to begin surveying the hull.
const EndOfPrg = "WALK"

type
  SpringOp = enum
    soAnd = (0, "AND")
    soOr = (1, "OR")
    soNot = (2, "NOT")

  ## These will be 1 if ground, 0 if hole.
  SpringSensor = enum
    ssOneTile = (1, "A")
    ssTwoTiles = (2, "B")
    ssThreeTiles = (3, "C")
    ssFourTiles = (4, "D")

  SpringReg = enum
    srTemp = "T"
    srJump = "J" ## If 1 at end of script, it jumps.

# The Intcode program expects ASCII inputs and outputs. It will begin by displaying a prompt; then, input the desired instructions one per line. End each line with a newline (ASCII code 10).

# If the springdroid falls into space, an ASCII rendering of the last moments of its life will be produced.

# A jump will land you 4 tiles out.
const prog = readFile("input/day21.txt").toProgram
echo prog.toPrettyProgram

proc feedStream(stream: Stream = newFileStream(stdin)): (m: Machine) -> Int =
  (m: Machine) => stream.readChar.Int

proc printIfAscii(i: Int, m: Machine) =
  if i < 128:
    stdout.write i.chr
  else:
    echo &"\p\p*** Non-ASCII output! Hull damage: {i}"

let m = makeMachine(
  prog,
  onInput = feedStream(newStringStream(
    "NOT A J\nWALK\n")),
  onOutput = printIfAscii)
m.run()
