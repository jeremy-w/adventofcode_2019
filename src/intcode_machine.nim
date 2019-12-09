import sequtils
import strformat
import strutils

type
  ## Intcode computer opcodes.
  ## Day 2: opAdd, opMultiply, opHalt
  Opcode* = enum
    opAdd = (1, "add")
    opMultiply = (2, "mul")
    opInput = (3, "inp")
    opOutput = (4, "out")
    opHalt = (99, "hlt")

  ## Parameter mode, for opcodes that take parameters.
  ParamMode* = enum
    pmPosition = 0  ## The parameter is the address of the value. This is the default.
    pmImmediate = 1 ## The parameter is the value itself.

  Instruction* = tuple
    op: Opcode
    params: seq[ParamMode]

  World* = ref object of RootObj

method onInput*(w: World): int {.base.} =
  stdin.readLine().parseInt

method onOutput*(w: World, i: int, ip: int, mem: seq[int]) {.base.} =
  echo &"output: {i}\n\tip: {ip}\n" #\tmem: {mem}\n"

func paramCount(op: Opcode): Natural =
  case op
  of opAdd, opMultiply: 3
  of opInput, opOutput: 1
  of opHalt: 0

## Instructions are encoded as digits from left-to-right mapping to argument modes from last to first, then opcode in last two digits.
func toInstruction(i: int): Instruction =
  var digits = i

  # Extract the opcode.
  result.op = (digits mod 100).Opcode
  digits = digits div 100

  # Then use that to determine how many params to read.
  var c = result.op.paramCount
  while c > 0:
    dec c

    # This conveniently defaults to 0.
    let pm = (digits mod 10).ParamMode
    digits = digits div 10

    result.params.add(pm)

## Runs an Intcode program.
##
## An Intcode machine's memory starts at address 0.
## An Opcode has zero or more parameters.
proc run*(program: seq[int], world = World()): seq[int] =
  var mem = program
  var ip = 0
  while true:
    let instruction = mem[ip].toInstruction
    let rawParams = mem[ip+1 ..< ip+1+instruction.op.paramCount]
    var paramValues: seq[int]
    for (mode, rawValue) in instruction.params.zip(rawParams):
      let param = case mode
        of pmPosition: mem[rawValue]
        of pmImmediate: rawValue
      paramValues.add(param)
    assert paramValues.len == rawParams.len

    echo fmt"running: {instruction}: {rawParams} => {paramValues}"

    case instruction.op
    of opAdd:
      assert rawParams.len == 3, fmt"got: {rawParams}"
      assert paramValues.len == 3, fmt"got: {paramValues}"
      mem[rawParams[2]] = paramValues[0] + paramValues[1]

    of opMultiply:
      mem[rawParams[2]] = paramValues[0] * paramValues[1]

    of opInput:
      mem[rawParams[0]] = world.onInput()

    of opOutput:
      world.onOutput(paramValues[0], ip, mem)

    of opHalt:
      return mem

    inc ip, 1 + instruction.op.paramCount

proc toProgram*(line: string): seq[int] =
  line.strip.split(",").map(parseInt)

proc toString*(mem: seq[int]): string =
  mem.mapIt($it).join(",")

proc runString*(text: string): string =
  run(text.toProgram).toString()

when defined(test):
  echo "# testing: intcode_machine"
  let got = 1002.toInstruction
  doAssert got == (op: 2.Opcode, params: @[0.ParamMode, 1.ParamMode,
      0.ParamMode]), fmt"got: {got}"
  echo "ok - toInstruction"
