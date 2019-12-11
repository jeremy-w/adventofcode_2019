import sequtils
import strformat
import strutils

type
  Memory* = seq[int]

  ## Intcode computer opcodes.
  ## Day 2: opAdd, opMultiply, opHalt
  Opcode* = enum
    opAdd = (1, "add")
    opMultiply = (2, "mul")
    opInput = (3, "inp")
    opOutput = (4, "out")
    opJumpIfTrue = (5, "bnz")
    opJumpIfFalse = (6, "brz")
    opLessThan = (7, "lt?")
    opEquals = (8, "eq?")
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
  of opAdd, opMultiply, opLessThan, opEquals: 3
  of opJumpIfTrue, opJumpIfFalse: 2
  of opInput, opOutput: 1
  of opHalt: 0

## Instructions are encoded as digits from left-to-right mapping to argument modes from last to first, then opcode in last two digits.
func toInstruction(i: int): Instruction =
  # debugEcho "instructionizing: ", i  # dies on 0
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
## Returns the final state of the memory.
proc run*(program: Memory, world = World()): Memory {.discardable.} =
  var mem = program
  var ip = 0
  var didJump = false
  while true:
    didJump = false
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

    of opLessThan:
      mem[rawParams[2]] = if paramValues[0] < paramValues[1]: 1 else: 0

    of opEquals:
      mem[rawParams[2]] = if paramValues[0] == paramValues[1]: 1 else: 0

    of opJumpIfTrue:
      if paramValues[0] != 0:
        echo &"  {paramValues[0]} is non-zero: jumping to {paramValues[1]}"
        ip = paramValues[1]
        didJump = true
      else:
        echo &"  {paramValues[0]} not non-zero: NOT jumping to {paramValues[1]}"

    of opJumpIfFalse:
      if paramValues[0] == 0:
        echo &"  {paramValues[0]} is zero: jumping to {paramValues[1]}"
        ip = paramValues[1]
        didJump = true
      else:
        echo &"  {paramValues[0]} is not zero: NOT jumping to {paramValues[1]}"

    of opInput:
      mem[rawParams[0]] = world.onInput()
      echo &"  input received: @{rawParams[0]} := {mem[rawParams[0]]}"

    of opOutput:
      world.onOutput(paramValues[0], ip, mem)

    of opHalt:
      return mem

    if not didJump:
      inc ip, 1 + instruction.op.paramCount

proc toProgram*(line: string): seq[int] =
  line.strip.split(",").map(parseInt)

proc toString*(mem: seq[int]): string =
  mem.mapIt($it).join(",")

proc toPrettyProgram*(prog: Memory): string =
  var ip = 0
  var lines = newSeq[string]()
  while ip < prog.len:
    try:
      var insn = prog[ip].toInstruction
      var line = $insn.op
      var args = prog[ip+1 .. ip+insn.op.paramCount]
      for i, arg in args:
        line &= " "
        case insn.params[i]
        of pmImmediate: line &= &"#{arg}"
        of pmPosition: line &= &"@{arg}"
      lines.add &"{ip}: {line}"
      inc ip, 1 + insn.op.paramCount
    except RangeError:
      lines.add &"{ip}: .data {prog[ip]}"
      inc ip
  result = lines.join("\n")

proc runString*(text: string): string =
  run(text.toProgram).toString()

type
  FixedInputWorld* = ref object of World
    inputs*: seq[int]
    outputs*: seq[int]
    shouldEcho*: bool

method onInput*(w: FixedInputWorld): int =
  if w.inputs.len > 1:
    w.inputs.pop
  else:
    w.inputs[0]

method onOutput*(w: FixedInputWorld, i: int, ip: int, mem: seq[int]) =
  w.outputs.add(i)
  if w.shouldEcho:
    procCall onOutput(w.World, i, ip, mem)

when defined(test):
  echo "# testing: intcode_machine"
  let got = 1002.toInstruction
  doAssert got == (op: 2.Opcode, params: @[0.ParamMode, 1.ParamMode,
      0.ParamMode]), fmt"got: {got}"
  echo "ok - toInstruction"

  echo "# day5 part2"
  var d5p2Tests = @[
    (name: "eq?pos true", prog: "3,9,8,9,10,9,4,9,99,-1,8".toProgram, inputs: @[
        8], expected: @[1]),
    (name: "eq?pos false", prog: "3,9,8,9,10,9,4,9,99,-1,8".toProgram,
        inputs: @[-1], expected: @[0]),
    (name: "lt?pos false", prog: "3,9,7,9,10,9,4,9,99,-1,8".toProgram,
        inputs: @[8], expected: @[0]),
    (name: "lt?pos true", prog: "3,9,7,9,10,9,4,9,99,-1,8".toProgram, inputs: @[
        7], expected: @[1]),
    (name: "eq?imm true", prog: "3,3,1108,-1,8,3,4,3,99".toProgram, inputs: @[
        8], expected: @[1]),
    (name: "eq?imm true", prog: "3,3,1108,-1,8,3,4,3,99".toProgram, inputs: @[
        -8], expected: @[0]),
    (name: "lt?imm false", prog: "3,3,1107,-1,8,3,4,3,99".toProgram,
          inputs: @[8],
      expected: @[0]),
    (name: "lt?imm true", prog: "3,3,1107,-1,8,3,4,3,99".toProgram, inputs: @[7],
      expected: @[1]),
    (name: "jmp - isNonZero true - pos",
        # inp @12
          # brz @12 @15  # @15: 9
          # add @13 @14 @13  # 0 + 1 => @13
          # 9: out @13  # @13: 0 initially
          # hlt
      prog: "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9".toProgram, inputs: @[1],
      expected: @[1]),
      (name: "jmp - isNonZero false - pos",
      prog: "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9".toProgram, inputs: @[0],
      expected: @[0]),
      (name: "jmp - isNonZero true - imm",
      prog: "3,3,1105,-1,9,1101,0,0,12,4,12,99,1".toProgram, inputs: @[1],
      expected: @[1]),
      (name: "jmp - isNonZero false - imm",
      prog: "3,3,1105,-1,9,1101,0,0,12,4,12,99,1".toProgram, inputs: @[0],
      expected: @[0]),
    ]
  for test in d5p2Tests:
    let w = FixedInputWorld(inputs: test.inputs)
    discard run(test.prog, w)
    try:
      doAssert w.outputs == test.expected, &"got: {w.outputs}, expected: {test.expected} - {test.name}"
      echo "ok - ", test.name
    except:
      echo "# ", getCurrentExceptionMsg()
      echo "not ok - ", test.name
