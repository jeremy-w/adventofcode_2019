import intcode_machine

type
    FixedInputWorld = ref object of World
        inputs*: seq[int]
        outputs*: seq[int]

method onInput(w: FixedInputWorld): int =
    if w.inputs.len > 1:
        w.inputs.pop
    else:
        w.inputs[0]

method onOutput(w: FixedInputWorld, i: int, ip: int, mem: seq[int]) =
    w.outputs.add(i)
    procCall onOutput(w.World, i, ip, mem)

let diagnosticProgram = readFile("./input/day5.txt").toProgram
const airConditionerUnitId = 1
var world = FixedInputWorld(inputs: @[airConditionerUnitId])
let finalState = diagnosticProgram.run(world = world)
echo "final state: ", finalState
