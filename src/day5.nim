import intcode_machine
import sequtils
import strformat

let diagnosticProgram = readFile("./input/day5.txt").toProgram

echo "part 1:"
const airConditionerUnitId = 1
var world = FixedInputWorld(inputs: @[airConditionerUnitId])
discard diagnosticProgram.run(world = world)
assert world.outputs[0..^2].allIt it == 0
let part1Answer = world.outputs[^1]
echo "result: ", part1Answer
assert part1Answer == 12440243, &"got: {part1Answer}"

echo "\n=====\n\npart 2:"
const thermalRadiatorControllerId = 5
var world2 = FixedInputWorld(inputs: @[thermalRadiatorControllerId])
discard diagnosticProgram.run(world = world2)
assert world2.outputs[^1] == 15486302
