# Run with:
#   nimble run ex01 ./input.txt
#   nimble run ex01 -d:2 ./input.txt
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

func test =
  const masses = [12, 14, 1969, 100756]
  const expected = [2, 2, 654, 33583]
  for (mass, shouldBe) in masses.zip(expected):
    var fuel = fuelForMass(mass)
    doAssert(fuel == shouldBe)

proc main =
  var filename: string
  # Yeah, OK, this param name makes no sense. Not gonna fix it.
  var day = 1

  # BUG: nimble run ex01 --help intercepts --help rather than passing, in spite of docs.
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
    stderr.writeLine("usage: ex01 -d:PART INPUTPATH")
    quit(QuitFailure)

  var massFn = if day == 1: fuelForMass else: includingFuelMass

  var masses = toSeq(filename.lines).map(line => parseInt(line).Natural)
  var fuelNeeded = sum(masses.map(massFn))
  echo(fuelNeeded)


when isMainModule:
  test()
  main()
