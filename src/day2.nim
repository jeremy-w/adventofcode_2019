import strutils, sequtils, strformat

type
    Opcode = enum
        opAdd = (1, "+")
        opMultiply = (2, "*")
        opHalt = (99, ".")

proc run(program: seq[int]): seq[int] =
    var mem = program
    var pc = 0
    while true:
        let op = mem[pc].Opcode
        inc pc

        case op
        of opAdd, opMultiply:
            let leftAddr = mem[pc]
            let left = mem[leftAddr]
            inc pc

            let rightAddr = mem[pc]
            let right = mem[rightAddr]
            inc pc

            let resAddr = mem[pc]
            inc pc

            let output = if op == opAdd: left + right else: left * right
            mem[resAddr] = output
        of opHalt:
            return mem

proc toProgram(line: string): seq[int] =
    line.strip.split(",").map(parseInt)

proc toString(mem: seq[int]): string =
    mem.mapIt($it).join(",")

proc runString(text: string): string =
    run(text.toProgram).toString()

# Run with: nimble -d:test run day2.nim
when defined(test):
    const tests = @[
    ("1,0,0,0,99", "2,0,0,0,99"),
    ("2,3,0,3,99", "2,3,0,6,99"),
    ("2,4,4,5,99,0", "2,4,4,5,99,9801"),
    ("1,1,1,4,99,5,6,0,99", "30,1,1,4,2,5,6,0,99"),
    ]
    for (input, expectedOutput) in tests:
        let output = runString(input)
        doAssert output == expectedOutput, fmt"got {output} but expected {expectedOutput} for {input}"
    echo tests.len, " tests passed"
    quit(QuitSuccess)

proc restore1202ProgramAlarmState(program: seq[int]): seq[int] =
    var output = program
    output[1] = 12
    output[2] = 2
    return output

when isMainModule:
    let program = stdin.readLine().toProgram()
    let readyToRun = restore1202ProgramAlarmState(program)
    echo run(readyToRun).toString()
