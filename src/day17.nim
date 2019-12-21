#[
 Locate all scaffold intersections; for each, its alignment parameter is the distance between its left edge and the left edge of the view multiplied by the distance between its top edge and the top edge of the view.

Run your ASCII program. What is the sum of the alignment parameters for the scaffold intersections?
]#
import intcode_machine_v2
import math
import sequtils
import strformat
import strutils

func alignmentParam(x, y: int): auto = x * y
func sumOfAlignmentParams(params: openArray[tuple[c, r: int]]): auto =
  params
  .mapIt(alignmentParam(it.c, it.r))
  .sum

var s: string
proc accumulateOutput(i: Int, m: Machine) =
  s.add i.char

const prog = readFile("input/day17.txt").toProgram
let m = makeMachine(prog, onOutput = accumulateOutput)
m.run()
echo s

func neighbors(c, r: int; lines: openArray[string]): tuple[t, b, l, r: char] =
  result.t = if r > lines.low: lines[r-1][c] else: '\0'
  result.b = if r < lines.high: lines[r+1][c] else: '\0'
  result.l = if c > 0: lines[r][c-1] else: '\0'
  result.r = if c < lines[0].high: lines[r][c+1] else: '\0'

func findIntersections(s: string): seq[tuple[c, r: int]] =
  let lines = s.splitLines.filterIt it.contains('.') or it.contains('#')
  let nrows = lines.len
  let ncols = lines[0].len
  debugEcho &"{nrows} rows of {ncols} cols"
  for c in 0 ..< ncols:
    for r in 0 ..< nrows:
      if neighbors(c, r, lines) == (t: '#', b: '#', l: '#', r: '#'):
        result.add (c: c, r: r)

let intersections = findIntersections(s)
echo "intersections: ", intersections.join("\p")
echo "sum of alignment params: ", intersections.sumOfAlignmentParams
