import sequtils
import strformat
import strutils
import sugar

type
  Int* = BiggestInt
  Memory* = seq[Int]

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

  Machine* = ref object of RootObj
    id: string
    ip: Int
    relativeBase: Int
    mem: Memory
    onInput: (Machine) -> Int
    onOutput: (Int, Machine) -> void

proc defaultOnInput(m: Machine): Int = 0
proc defaultOnOutput(i: Int, m: Machine) = echo &"OUTPUT: {i} from {m.id}"

func makeMachine*(
  mem: Memory,
  id: string = "",
  onInput: (Machine) -> Int = defaultOnInput,
    onOutput: (Int, Machine) -> void = defaultOnOutput
  ): Machine = Machine(
    id: id,
    mem: mem,
    onInput: onInput,
    onOutput: onOutput)

func paramCount(op: Opcode): Natural =
  case op
  of opAdd, opMultiply, opLessThan, opEquals: 3
  of opJumpIfTrue, opJumpIfFalse: 2
  of opInput, opOutput: 1
  of opHalt: 0

## Instructions are encoded as digits from left-to-right mapping to argument modes from last to first, then opcode in last two digits.
func toInstruction*(i: Int): Instruction =
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

proc store(m: Machine, index: Int, value: Int) =
  if index >= m.mem.len:
    m.mem.setLen index + 1
  m.mem[index] = value

proc load(m: Machine, index: Int): Int =
  if index >= m.mem.len:
    return 0
  return m.mem[index]

## Runs an Intcode program.
##
## An Intcode machine's memory starts at address 0.
## An Opcode has zero or more parameters.
## Returns the final state of the memory.
proc run*(m: Machine) =
  m.ip = 0
  var didJump = false
  while true:
    let instruction = m.load(m.ip).toInstruction
    let paramCount = instruction.op.paramCount
    var rawParams: seq[Int]
    var paramValues: seq[Int]
    for i, mode in instruction.params:
      let rawValue = m.load(m.ip + 1 + i)
      rawParams.add rawValue
      let param = case mode
        of pmPosition: m.load(rawValue)
        of pmImmediate: rawValue
      paramValues.add(param)
    assert paramValues.len == rawParams.len
    assert paramValues.len == paramCount

    echo fmt"running: {instruction}: {rawParams} => {paramValues}"
    didJump = false
    case instruction.op
    of opAdd:
      assert rawParams.len == 3, fmt"got: {rawParams}"
      assert paramValues.len == 3, fmt"got: {paramValues}"
      let value = paramValues[0] + paramValues[1]
      m.store(rawParams[2], value)

    of opMultiply:
      let value = paramValues[0] * paramValues[1]
      m.store(rawParams[2], value)

    of opLessThan:
      let value = if paramValues[0] < paramValues[1]: 1 else: 0
      m.store(rawParams[2], value)

    of opEquals:
      let value = if paramValues[0] == paramValues[1]: 1 else: 0
      m.store(rawParams[2], value)

    of opJumpIfTrue:
      if paramValues[0] != 0:
        echo &"  {paramValues[0]} is non-zero: jumping to {paramValues[1]}"
        m.ip = paramValues[1]
        didJump = true
      else:
        echo &"  {paramValues[0]} not non-zero: NOT jumping to {paramValues[1]}"

    of opJumpIfFalse:
      if paramValues[0] == 0:
        echo &"  {paramValues[0]} is zero: jumping to {paramValues[1]}"
        m.ip = paramValues[1]
        didJump = true
      else:
        echo &"  {paramValues[0]} is not zero: NOT jumping to {paramValues[1]}"

    of opInput:
      let value = m.onInput(m)
      m.store(rawParams[0], value)
      echo &"  input received: @{rawParams[0]} := {m.mem[rawParams[0]]}"

    of opOutput:
      m.onOutput(paramValues[0], m)

    of opHalt:
      return

    if not didJump:
      inc m.ip, 1 + instruction.op.paramCount

proc toProgram*(line: string): seq[Int] =
  line.strip.split(",").map(parseBiggestInt)

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
    except RangeError, IndexError:
      lines.add &"{ip}: .data {prog[ip]}"
      inc ip
  result = lines.join("\n")

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
    var outputs: seq[Int]
    let m = makeMachine(mem = test.prog, id = test.name, onInput = (
        m: Machine) => test.inputs[0].BiggestInt, onOutput = (i: Int,
            m: Machine) => outputs.add i)
    m.run()
    try:
      doAssert outputs == test.expected.mapIt it.BiggestInt, &"got: {outputs}, expected: {test.expected} - {test.name}"
      echo "ok - ", test.name
    except:
      echo "# ", getCurrentExceptionMsg()
      echo "not ok - ", test.name

  # day9: relative mode addressing, large memory (setLen index+1 as needed), bignums (i64)
  echo "\L\L== DAY 9 TESTS =="
  echo "QUINE"
  var outputs: seq[Int]
  let quine = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99"
  var m = makeMachine(mem = quine.toProgram, id = "quine", onOutput = (i: Int,
      m: Machine) => outputs.add i)
  m.run()
  doAssert outputs == quine.toProgram

  echo "16 DIGITS"
  outputs.setLen(0)
  let sixteenDigitOutput = "1102,34915192,34915192,7,4,7,99,0"
  m = makeMachine(mem = sixteenDigitOutput.toProgram, id = "sixteenDigitOutput",
      onOutput = (i: Int, m: Machine) => outputs.add i)
  m.run()
  doAssert outputs.len == 1
  doAssert ($outputs[0]).len == 16

  echo "BIGNUM"
  outputs.setLen(0)
  let bignum = "104,1125899906842624,99"
  m = makeMachine(mem = bigNum.toProgram, id = "bignum",
      onOutput = (i: Int, m: Machine) => outputs.add i)
  m.run()
  doAssert outputs == @[1125899906842624'i64]
