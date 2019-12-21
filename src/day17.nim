#[
 Locate all scaffold intersections; for each, its alignment parameter is the distance between its left edge and the left edge of the view multiplied by the distance between its top edge and the top edge of the view.

Run your ASCII program. What is the sum of the alignment parameters for the scaffold intersections?
]#
import math
import sequtils

func alignmentParam(x, y: int): auto = x * y
func sumOfAlignmentParams(params: openArray[tuple[x, y: int]]): auto =
  params
  .mapIt(alignmentParam(it.x, it.y))
  .sum
