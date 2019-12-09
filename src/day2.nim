import intcode_machine

# Run with: nimble -d:test run day2.nim
when defined(test):
    import strformat

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
