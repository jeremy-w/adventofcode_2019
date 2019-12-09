import sequtils
import strutils

type
  ## Intcode computer opcodes.
  ## Day 2: opAdd, opMultiply, opHalt
  Opcode* = enum
    opAdd = (1, "+")
    opMultiply = (2, "*")
    opHalt = (99, ".")

## Runs an Intcode program.
##
## An Intcode machine's memory starts at address 0.
## An Opcode has zero or more parameters.
proc run*(program: seq[int]): seq[int] =
  var mem = program
  var ip = 0
  while true:
    let op = mem[ip].Opcode
    inc ip

    case op
    of opAdd, opMultiply:
      let leftAddr = mem[ip]
      let left = mem[leftAddr]
      inc ip

      let rightAddr = mem[ip]
      let right = mem[rightAddr]
      inc ip

      let resAddr = mem[ip]
      inc ip

      let output = if op == opAdd: left + right else: left * right
      mem[resAddr] = output

    of opHalt:
      return mem

proc toProgram*(line: string): seq[int] =
  line.strip.split(",").map(parseInt)

proc toString*(mem: seq[int]): string =
  mem.mapIt($it).join(",")

proc runString*(text: string): string =
  run(text.toProgram).toString()
