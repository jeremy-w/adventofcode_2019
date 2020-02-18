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

#[
  Jump if not A:

  jump if not (B or C) and D

  (or
    (and [not (or b c false)] d)
    (not a))
]#
# fails for: #..#@#
let try1 = """
NOT A J
WALK
"""
# fails for what try1 dodges: #.#
let try2 = """
OR B J
OR C J
NOT J J
AND D J
WALK
"""
  # fails for: #.#.@#, so the mirror of try1
  # would be avoided by: a b (not c) d
let try3 = """
OR B J
OR C J
NOT J J
AND D J
NOT A T
OR T J
WALK
"""

# Huh, this made it!
# *** Non-ASCII output! Hull damage: 19359316
let try4 = """
OR B J
OR C J
NOT J J
AND D J
NOT A T
OR T J
NOT C T
AND A T
AND B T
AND D T
OR T J
WALK
"""
let part1Solution = try4

# Instead of ending your springcode program with WALK, use RUN. Doing this will enable extended sensor mode, capable of sensing ground up to nine tiles away. Use registers EFGHI for 56789.

# Fails the same as try1.
# I thought maybe running would let it clear more spaces on a jump, but it doesn't. Still just 4.
let p2try1 = """
NOT A J
RUN
"""

# Yeah, RUN just unlocks more "map".
#[
This fails after 2 jumps. It jumps to the X, then falls in.
  ......@..........
  #####.X.##.#.####

  #.#.##@#.#

  would be avoided by not jumping on the try4 fix,
  or probably better: teaching it to recognize this bigger pattern of on/off. but we only have 3 lines left to work with, yikes.
]#
let p2try2 = part1Solution.replaceWord("WALK", "RUN")

# fails on 2.-1#-2.-2#-1.
# #..#@.##.#
let p2try3 = """
OR B J
OR C J
NOT J J
AND D J
AND I J
NOT A T
OR T J
NOT C T
AND A T
AND B T
AND D T
OR T J
RUN
"""
let m = makeMachine(
  prog,
  onInput = feedStream(newStringStream(p2try3)),
  onOutput = printIfAscii)
m.run()
