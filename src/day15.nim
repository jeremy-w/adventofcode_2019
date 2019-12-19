#[
Day 15: Maze.

You can't see anything to start with, so you have to discover your environment.
]#
import intcode_machine_v2
import sequtils

type
  MoveCmd = enum
    mcN = (1, "n")
    mcS = (2, "s")
    mcW = (3, "w")
    mcE = (4, "e")

  StatusReply = enum
    srHitWall
    srDidMove
    srFoundIt

const
  VarRange = 1032..1044
  MazeRange = 252..1031
  VarNames = {
    1032: "CmpResult",
    1033: "MoveCmd",
    1034: "CurrCol",
    1035: "CurrRow",
    1039: "MoveCol",
    1040: "MoveRow",
    1044: "StatusReply",
  }

const prog = readFile("input/day15.txt").toProgram
echo prog.toPrettyProgram(@[VarRange, MazeRange], VarNames.mapIt (it[0].Int, it[1]))

#[
  What is the fewest number of movement commands required to move the repair droid from its starting position to the location of the oxygen system?
]#
