import algorithm
import sequtils
import strformat
import strutils
import intcode_machine

const
  AmpCnt = 5
  InitialInputSignal = 0

proc runAmplifiers(program: Memory, phaseSettings: openArray[int]): int =
  assert phaseSettings.len == AmpCnt
  echo &"\n\nPHASES: {phaseSettings}"
  var i = 0
  var prevAmpOutput = InitialInputSignal
  while i < AmpCnt:
    echo &"amp {i}: ph={phaseSettings[i]} i={prevAmpOutput}"
    let w = FixedInputWorld(inputs: @[phaseSettings[i], prevAmpOutput])
    run(program, w)
    assert w.outputs.len == 1, &"got {w.outputs.len} outputs, but expected exactly 1"
    prevAmpOutput = w.outputs[0]
    inc i
  result = prevAmpOutput
  echo &"==> {result}"

proc findMaxAmplification(program: Memory): tuple[maxOutput: int,
    maxSettings: seq[int]] =
  var phaseSettings = "01234".toSeq.mapIt(($it).parseInt)
  result.maxOutput = runAmplifiers(program, phaseSettings)
  result.maxSettings = phaseSettings
  while phaseSettings.nextPermutation:
    let output = runAmplifiers(program, phaseSettings)
    if output > result.maxOutput:
      result.maxOutput = output
      result.maxSettings = phaseSettings

when defined(test):
  echo "# d7p1 examples"
  let tests = @[
    (p: "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0", r: (maxOutput: 43210,
        maxSettings: @[4, 3, 2, 1, 0])),
  ]
  echo &"1..{tests.len}"
  for i, test in tests:
    let r = findMaxAmplification(test.p.toProgram)
    doAssert r == test.r, &"got {r}, expected {test.r}"
    echo "ok {i}"
  quit(QuitSuccess)

when isMainModule:
  echo "day 7, part 1:"
  var program = readFile("input/day7.txt").toProgram
  echo program.toPrettyProgram
  let (maxOutput, maxSettings) = findMaxAmplification(program)
  echo &"\tmaxOutput: {maxOutput} from phase settins: {maxSettings}"
