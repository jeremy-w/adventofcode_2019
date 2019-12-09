import intcode_machine
import strformat

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

proc gravityAssist(program: seq[int], noun: int, verb: int): seq[int] =
    var output = program
    output[1] = noun
    output[2] = verb
    return output

proc restore1202ProgramAlarmState(program: seq[int]): seq[int] =
    program.gravityAssist(noun = 12, verb = 2)

when isMainModule:
    let program = stdin.readLine().toProgram()
    let readyToRun = restore1202ProgramAlarmState(program)
    let mem = run(readyToRun)
    let output = mem[0]
    echo "day 2, part 1: the 1202 error has an output of: ", output

    const targetOutput = 19690720
    var noun = -1
    var verb = -1
    block noun_search:
        while noun <= 99:
            inc noun
            verb = -1
            while verb <= 99:
                inc verb
                let output = program.gravityAssist(noun = noun,
                        verb = verb).run[0]
                # echo fmt"{noun}, {verb} => {output}"
                if output == targetOutput:
                    let answer = 100*noun + verb
                    echo fmt"day 2, part 2: noun = {noun}; verb = {verb}; 100*noun + verb = {answer}"
                    break noun_search
