#[
Day 15: Maze.

You can't see anything to start with, so you have to discover your environment.
]#
import intcode_machine_v2
import sequtils
import strformat
import strutils
import terminal

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

const prog = readFile("input/day15.txt").toProgram

proc disas() {.used.} =
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
  echo prog.toPrettyProgram(@[VarRange, MazeRange], VarNames.mapIt (it[0].Int, it[1]))

# disas()

#[
  What is the fewest number of movement commands required to move the repair droid from its starting position to the location of the oxygen system?
  ]#
const
  Wall = '#'
  Floor = '.'
  You = '@'
  Oxygen = 'X'
  Start = 'O'
  Unknown = ' '

proc nextMove(): MoveCmd =
  while true:
    let c = getch()
    # By handling ABCD, we get arrow keys without worrying about the \e[ part.
    case c
    of 'n', 'A': return mcN
    of 'e', 'C': return mcE
    of 's', 'B': return mcS
    of 'w', 'D': return mcW
    of 'q': quit QuitSuccess
    else: continue

type Screen = ref object of RootObj
  disp: array[41, array[41, char]]
  pos: tuple[c: int, r: int]
  move: MoveCmd
  moveCnt: int

proc makeScreen(): Screen =
  result = Screen(pos: (c: 21, r: 21))
  for i, r in result.disp:
    for j, _ in r:
      result.disp[i][j] = if i == 21 and j == 21: Start else: Unknown

func displayString(s: Screen): string =
  var lines = newSeqOfCap[string](s.disp.len + 2)
  lines.add "   " & repeat(' ', 10) & repeat('1', 10) & repeat('2', 10) &
      repeat('3', 10) & '4'
  lines.add "   " & repeat("0123456789", 4) & "0"
  for i, r in s.disp:
    var line = &"{i:2} "
    for j, c in r:
      let isCurrPos = s.pos.r == i and s.pos.c == j
      if c == Oxygen or not isCurrPos:
        line.add c
      else:
        line.add You
    lines.add line
  result = lines.join("\p")


proc draw(s: Screen) =
  echo "---"
  echo s.displayString
  echo &"\pMoves: {s.moveCnt}"

proc askMove(s: Screen): Int =
  s.draw()
  s.move = nextMove()
  inc s.moveCnt
  result = s.move.Int

proc processReply(s: Screen, r: Int) =
  let prevPos = s.pos

  case s.move
    of mcN: s.pos.r -= 1
    of mcS: s.pos.r += 1
    of mcE: s.pos.c += 1
    of mcW: s.pos.c -= 1

  case r.StatusReply
  of srDidMove:
    s.disp[s.pos.r][s.pos.c] = Floor
  of srFoundIt:
    s.disp[s.pos.r][s.pos.c] = Oxygen
  of srHitWall:
    s.disp[s.pos.r][s.pos.c] = Wall
    s.pos = prevPos

echo "Legend: #=wall, .=floor, @=you, X=oxygen, blank=mystery"
echo "Navigate with nsew. Quit with q."

var screen = makeScreen()
var machine = makeMachine(prog, onInput = proc (
    m: Machine): Int = screen.askMove(), onOutput = proc (i: Int,
    m: Machine) = screen.processReply(i))

# Changing the starting location generates a different map!
# machine.store(1034, 3)
# machine.store(1035, 5)
# screen.pos = (c: 3, r: 5)

machine.run()

# Explored by hand
const minimalMap = """
---
 0
 1  ...
 2  .#.
 3  .#...
 4  .###.#
 5  .#X .
 6  .#.#.
 7  .#...
 8  .######
 9  .......
10       #.               ###
11       #.              #...#
12       #.##            #.#. #
13        ...#           #. ...#
14        ##.#           #. ##. #
15       #...            #.   ...#
16       #.#        ### ##.#  # .#
17       #...      #...#...  #...#
18        ##.##   ##.#. .    #.##
19          ...# #...#...     ...
20    ##### ##.# #.######     ##.#
21   #.....#...   ......O   .....
22   #.# #.#.       ### #  #.####
23  ... ...#.      #...#...#.....
24  .# #.## .     ##. .#.#. ####.#
25 #.#  .....    #...#...#.....#.
26  . #####      #.#         #.#.
27  .#.....#     #.          #...
28  .#.   .#     #.
29  .#.   .#     #.
30  .#.   .#     #.
31  .#.   .#     #...
32  .#. ##.#      ##.
33  .#. ...        #...
34  .#. . ###   ### ##.#
35  ... .#...# #...#...
36  #   .#.#.###.#.#.
37      ... .....#...
38       #        ##
39                     """
let stepCount = minimalMap.filterIt(it == Oxygen or it == Floor).len
echo "stepCount: ", stepCount

echo "Part 2"
# Use the repair droid to get a complete map of the area. How many minutes will it take to fill with oxygen?
const maximalMap = ""
