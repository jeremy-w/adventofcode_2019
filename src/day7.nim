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
  proc echo(str: string) = discard
  echo &"\n\nPHASES: {phaseSettings}"
  var i = 0
  var prevAmpOutput = InitialInputSignal
  while i < AmpCnt:
    echo &"amp {i}: ph={phaseSettings[i]} i={prevAmpOutput}"
    # INPUTS ARE A STACK
    let w = FixedInputWorld(inputs: @[phaseSettings[i], prevAmpOutput].reversed)
    run(program, w)
    assert w.outputs.len == 1, &"got {w.outputs.len} outputs, but expected exactly 1"
    prevAmpOutput = w.outputs[0]
    inc i
  result = prevAmpOutput
  echo &"==> {result}"

type
  PipeChan*[T] = tuple
    input: ptr Channel[T]
    output: ptr Channel[T]

  ## A world whose input and output blocks on channels.
  ## Intended for use by per-thread machines.
  ChannelWorld = ref object of World
    id*: int
    pipe*: PipeChan[int]

  AmpThreadArgs = tuple
    id: int
    program: Memory
    pipe: PipeChan[int]

method onInput(w: ChannelWorld): int =
  echo &"CHAN {w.id} RECV"
  result = w.pipe.input[].recv
  echo &"CHAN {w.id} GOT: ", result

method onOutput(w: ChannelWorld, i: int, ip: int, mem: seq[int]) =
  echo &"CHAN {w.id} OUT: ", i
  w.pipe.output[].send(i)

proc amplifierThread(targs: AmpThreadArgs) {.thread.} =
  var w = ChannelWorld(pipe: targs.pipe, id: targs.id)
  echo "Running machine: ", targs.id
  run(targs.program, w)
  echo "Machine halted: ", targs.id

proc sanityCheck(chan: ptr Channel[int]) {.thread.} =
  echo "SANITY: look i got me an int: ", chan[].recv

# "Channels cannot be passed between threads. Use globals or pass them by ptr."
# Let's do both, inspired by: https://github.com/nim-lang/Nim/blob/1f8c9aff1f8de7294c5326c7e986779ab27f0239/tests/threads/ttryrecv.nim
var chans: array[0..AmpCnt-1, Channel[int]]

proc runFeedbackAmplifiers(program: Memory, phaseSettings: openArray[int]): int =
  assert phaseSettings.len == AmpCnt
  assert phaseSettings.allIt 5 <= it and it <= 9
  echo &"FEEDBACK ENGAGED: phaseSettings={phaseSettings}"
  var
    threads: array[0..AmpCnt-1, Thread[AmpThreadArgs]]
  assert threads.len == AmpCnt

  # Create and open all the channels.
  for i in chans.low..chans.high:
    chans[i] = Channel[int]()
    chans[i].open(maxItems = 1)

  # Start all the machines running. Send their phase config.
  for i in threads.low..threads.high:
    let currChanIdx = i
    # Last machine writes out to the first.
    let nextChanIdx =
      if i < chans.high:
        i + 1
      else:
        # The last machine writes to the first channel.
        chans.low

    # Send phase setting.
    let phaseSetting = phaseSettings[currChanIdx - threads.low]
    chans[currChanIdx].send(phaseSetting)

    echo &"wiring thread {i} to read {currChanIdx} and write {nextChanIdx}"
    createThread(
      threads[i],
      amplifierThread,
      (id: i, program: program,
      pipe: (input: addr chans[currChanIdx], output: addr chans[nextChanIdx])))

  # Prime the initial input.
  echo "sending initial input"
  chans[0].send(0)
  # var tid: Thread[ptr Channel[int]]
  # createThread(tid, sanityCheck, addr chans[0])
  # chans[0].send(0)
  echo "joining…"
  joinThreads(threads)
  echo "all threads complete"

  # Read the final output to the first machine from the last, if any.
  var outputChan = chans[chans.low]
  result =
    if outputChan.peek > 0:
      outputChan.recv
    else:
      -1
  echo &"FEEDBACK OUTPUT: {result} for {phaseSettings}"



proc findMaxAmplification(program: Memory, useFeedback = false): tuple[
    maxOutput: int, maxSettings: seq[int]] =
  var phaseChars =
    if useFeedback:
      "56789"
    else:
      "01234"
  var phaseSettings = phaseChars.toSeq.mapIt(($it).parseInt)

  let runProc =
    if useFeedback:
      runFeedbackAmplifiers
    else:
      runAmplifiers

  result.maxSettings = phaseSettings
  result.maxOutput = runProc(program, phaseSettings)

  while phaseSettings.nextPermutation:
    let output = runProc(program, phaseSettings)
    if output > result.maxOutput:
      result.maxSettings = phaseSettings
      result.maxOutput = output

when defined(test):
  echo "# d7p1 examples"
  let tests = @[
    # last two positions are phase and input
      # phase doubles as output
      # out = phase + 10*input
        # 4321 from: 10*(10*(10*(10*40 + 30) + 20) + 10) + 0
        # would expect successive outputs of: 40, 430, 4320, 43210
        # 0: inp @15 ; PHASE
        # 2: inp @16 ; INPUT
        # 4: mul @16 #10 @16 ; 10*INPUT
        # 8: add @16 @15 @15 ; OUTPUT = PHASE + 10*INPUT
        # 12: out @15
        # 14: hlt
        # 15: .data 0 (PHASE/OUT)
        # 16: .data 0 (INPUT)
    (p: "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0", r: (maxOutput: 43210,
        maxSettings: @[4, 3, 2, 1, 0])),
  ]
  echo &"1..{tests.len}"
  # for i, test in tests:
  #   let r = findMaxAmplification(test.p.toProgram)
  #   doAssert r == test.r, &"got {r}, expected {test.r} from {test.p.toProgram.toPrettyProgram}"
  #   echo &"ok {i}"

  echo "# d7p2 examples"
  let feedbackTests = @[
    (p: "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5",
        r: (maxOutput: 139629729, maxSettings: @[9, 8, 7, 6, 5])),
  ]
  echo &"1..{feedbackTests.len}"
  for i, test in feedbackTests:
    let r = findMaxAmplification(test.p.toProgram, useFeedback = true)
    doAssert r == test.r, &"got {r}, expected {test.r} from {test.p.toProgram.toPrettyProgram}"
    echo &"ok {i}"

  quit(QuitSuccess)

when isMainModule:
  echo "day 7, part 1:"
  var program = readFile("input/day7.txt").toProgram
  echo program.toPrettyProgram
  let (maxOutput, maxSettings) = findMaxAmplification(program)
  echo &"\tmaxOutput: {maxOutput} from phase settings: {maxSettings}"

  echo "day 7, part 2:"
  let feedback = findMaxAmplification(program, useFeedback = true)
  echo &"\tmaxOutput: {feedback.maxOutput} from phase settings: {feedback.maxSettings}"
