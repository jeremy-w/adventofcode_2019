import intcode_machine_v2
import strutils
import sugar

const
  TestModeInput = 1

when isMainModule:
  let prog = readFile("input/day9.txt").toProgram
  var outputs: seq[Int]
  let m = makeMachine(id = "BOOST", mem = prog, onInput = (m: Machine) =>
      TestModeInput.Int, onOutput = (i: Int, m: Machine) => outputs.add i)
  echo "=== DAY 9, PART 1: Test Mode ==="
  m.run()
  echo "\L\L=== OUTPUTS ===\L", outputs.join("\L")
