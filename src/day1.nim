# Run with:
#   nimble run day1 input/day1.txt
#   nimble run day1 -d:2 input/day1.txt
# Completes basically instantly. Yay nim.
import math
import parseopt
import sequtils
import strutils
import sugar
import system/io

func fuelForMass(mass: Natural): int =
  var fraction = trunc(mass / 3)
  result = fraction.int - 2

func includingFuelMass(mass: Natural): Natural =
  result = 0
  # When I failed to cast, m was a Natural, and then assignment failed a range check when fuelForMass returned -2.
  var m = mass.int
  while m > 0:
    m = fuelForMass(m)
    if m > 0:
      result += m

proc main =
  var filename: string
  # Yeah, OK, this param name makes no sense. Not gonna fix it.
  var day = 1

  # BUG: nimble run day1 --help intercepts --help rather than passing, in spite of docs.
  # (Also -- is just treated as an empty longopt.)
  var p = initOptParser()
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      filename = key
    of cmdShortOption:
      if key == "d":
        day = val.parseInt
    else:
      echo "invalid arg:", repr((kind: kind, key: key, val: val))

  if filename == "":
    stderr.writeLine("usage: day1 -d:PART INPUTPATH")
    quit(QuitFailure)

  var massFn = if day == 1: fuelForMass else: includingFuelMass

  var masses = toSeq(filename.lines).map(line => parseInt(line).Natural)
  var fuelNeeded = sum(masses.map(massFn))
  echo(fuelNeeded)

# To test, run with: nimble -d:test day1 input/day1.txt
when defined(test):
  const masses = [12, 14, 1969, 100756]
  const expected = [2, 2, 654, 33583]
  var i = 0
  for (mass, shouldBe) in masses.zip(expected):
    var fuel = fuelForMass mass
    doAssert fuel == shouldBe
    i += 1
  echo i, " tests passed"

when isMainModule and not defined(test):
  main()
