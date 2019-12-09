import sequtils
import strutils

type
  ## Intcode computer opcodes.
  ## Day 2: opAdd, opMultiply, opHalt
  Opcode* = enum
    opAdd = (1, "+")
    opMultiply = (2, "*")
    opHalt = (99, ".")

  ## Parameter mode, for opcodes that take parameters.
  ParamMode* = enum
    pmPosition = 0  ## The parameter is the address of the value. This is the default.
    pmImmediate = 1 ## The parameter is the value itself.

  Instruction = tuple
    op: Opcode
    params: seq[ParamMode]

func paramCount(op: Opcode): Natural =
  case op
  of opAdd, opMultiply: 2
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
proc run*(program: seq[int]): seq[int] =
  var mem = program
  var ip = 0
  while true:
    let instruction = mem[ip].toInstruction
    inc ip

    case instruction.op
    of opAdd, opMultiply:
      let leftAddr = mem[ip]
      let left = mem[leftAddr]
      inc ip

      let rightAddr = mem[ip]
      let right = mem[rightAddr]
      inc ip

      let resAddr = mem[ip]
      inc ip

      let output = if instruction.op == opAdd: left + right else: left * right
      mem[resAddr] = output

    of opHalt:
      return mem

proc toProgram*(line: string): seq[int] =
  line.strip.split(",").map(parseInt)

proc toString*(mem: seq[int]): string =
  mem.mapIt($it).join(",")

proc runString*(text: string): string =
  run(text.toProgram).toString()
