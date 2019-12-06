import math
import parseopt
import sequtils
import strutils
import sugar
import system/io

func fuelForMass(mass: Natural): Natural =
  result = (mass / 3).Natural - 2

func test =
  const masses = [12, 14, 1969, 100756]
  const expected = [2, 2, 654, 33583]
  for (mass, shouldBe) in masses.zip(expected):
    var fuel = fuelForMass(mass)
    doAssert(fuel == shouldBe)

proc main =
  var filename: string

  # BUG: nimble run ex01 --help intercepts --help rather than passing, in spite of docs.
  # (Also -- is just treated as an empty longopt.)
  var p = initOptParser()
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      filename = key
    else:
      echo "invalid arg:", repr((kind: kind, key: key, val: val))

  if filename == "":
    stderr.writeLine("usage: ex01 INPUTPATH")
    quit(QuitFailure)

  var masses = toSeq(filename.lines).map(line => parseInt(line).Natural)
  var fuelNeeded = sum(masses.map(fuelForMass))
  echo(fuelNeeded)


when isMainModule:
  test()
  main()
