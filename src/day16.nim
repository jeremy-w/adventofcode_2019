import math
import sequtils
import strutils
import strformat
# import nimprof

echo "=== AoC 2019, Day 16"
echo "--- Part 1"

const basePattern = [0, 1, 0, -1]
iterator patternForElementAtIndex(i: int): int =
  let repeatCount = i + 1
  for digit in basePattern:
    for _ in 1..repeatCount:
      yield digit

assert toSeq(patternForElementAtIndex(0)) == basePattern.toSeq
assert toSeq(patternForElementAtIndex(1)) == @[0, 0, 1, 1, 0, 0, -1, -1]

iterator applicablePattern(i: int): int =
  var first = true
  while true:
    # When applying the pattern, skip the very first value exactly once.
    for digit in patternForElementAtIndex(i):
      if first:
        first = false
        continue
      yield digit

proc runPhase(input: openArray[int]): seq[int] =
  result = newSeqOfCap[int](input.len)
  for outputIndex in 0 ..< input.len:
    var output = 0

    var i = 0
    for patternDigit in applicablePattern(outputIndex):
      if i > input.high:
        break
      let inputDigit = input[i]
      inc i

      if patternDigit == 0:
        discard
      elif patternDigit == 1:
        inc output, inputDigit
      else:
        dec output, inputDigit
      # stdout.write &"{inputDigit}*{patternDigit} "

    let onesDigit = abs(output mod 10)
    # echo &" = {onesDigit}"
    result.add onesDigit

const ex1Digits = "12345678".mapIt ($it).parseInt
var ex1 = ex1Digits
for i, expected in @[
  "48226158",
  "34040438",
  "03415518",
  "01029498",
  ]:
    ex1 = ex1.runPhase
    let output = ex1.join("")
    assert output == expected, &"got: {output} instead of {expected} after running {i + 1} phases"
    echo &"ok - ex1: ran {i + 1} phases"

# After 100 phases of FFT, what are the first eight digits in the final output list?
const bigExDigits = "80871224585914546619083218645595".mapIt ($it).parseInt
var bigEx = bigExDigits
for i in 1..100:
  bigEx = bigEx.runPhase
assert bigEx.join("")[0..<8] == "24176176"
echo &"ok - bigEx 100 phases"

const puzzleString = readFile("input/day16.txt").strip()
echo &"len: {puzzleString.len}"
assert puzzleString.len == 650
assert puzzleString.len == 5^2 * 2 * 13
const puzzleDigits = puzzleString.mapIt ($it).parseInt
var puzzle = puzzleDigits
for i in 1..100:
  puzzle = puzzle.runPhase

let firstEightDigits = puzzle.join("")[0..<8]
echo &"first 8 digits after 100 phases: {firstEightDigits}"
assert firstEightDigits == "49254779"

echo "\p--- Part 2"
# The real signal is your puzzle input repeated 10000 times.
var realSignal = repeat(puzzleString, 10_000).mapIt ($it).parseInt
echo &"signal length: {realSignal.len}"
assert realSignal.len == 6500000
assert realSignal.len == 5^6 * 2^5 * 13

# The first seven digits of your initial input signal also represent the message offset.
const messageOffsetString = puzzleString[0..<7]
assert messageOffsetString.len == 7
const messageOffset = messageOffsetString.parseInt
echo &"message offset: {messageOffset}"
assert messageOffset == 5979351

# Patterns are still calculated as before, and 100 phases of FFT are still applied.
echo "Running 100 phases on that massive input."
for i in 1..100:
  echo i
  realSignal = realSignal.runPhase

# the message offset indicates the number of digits to skip before reading the eight-digit message
let message = realSignal[messageOffset ..< (messageOffset + 8)]
echo &"message: {message}"
