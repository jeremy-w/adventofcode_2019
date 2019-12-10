import sequtils
import sets
import strformat
import strutils
import tables

const
  centerOfMass = "COM"
  you = "YOU"
  santa = "SAN"
  isOrbitedBy = ")"

type
  Orbit = tuple[center: string, satellite: string]
  OrbitMap = seq[Orbit]
  OrbitMapTable = Table[string, string]

proc asOrbit(line: string): Orbit =
  let parts = line.strip.split(isOrbitedBy)
  doAssert parts.len == 2, fmt"bad line: {line}"
  return (center: parts[0], satellite: parts[1])

proc asOrbitMap(lines: string): OrbitMap =
  lines
  .splitLines
  .filterIt(isOrbitedBy in it)
  .mapIt(it.asOrbit)

proc asOrbitMapTable(om: OrbitMap): OrbitMapTable =
  om.mapIt((it.satellite, it.center)).toTable

proc pathToCenterOfMass(omt: OrbitMapTable, sat: string): seq[string] =
  var curr = omt[sat]
  while curr != centerOfMass:
    result.add(curr)
    curr = omt[curr]

proc directAndIndirectOrbitCount(om: OrbitMap): int =
  let satelliteToCenterTable = om.mapIt((it.satellite, it.center)).toTable
  for satellite in satelliteToCenterTable.keys:
    var curr = satellite
    while curr != centerOfMass:
      inc result
      curr = satelliteToCenterTable[curr]

proc minOrbitalTransfersRequired(omt: OrbitMapTable; sat1, sat2: string): int =
  let p1 = omt.pathToCenterOfMass(sat1)
  let p2 = omt.pathToCenterOfMass(sat2)
  let possibleTransferPoints = p1.toHashSet.intersection(p2.toHashSet)
  let earliestTransferPoint = p1.filterIt(it in possibleTransferPoints)[0]
  result = p1.find(earliestTransferPoint) + p2.find(earliestTransferPoint)

when defined(test):
  echo "# testing: day6"

  doAssert "COM)B".asOrbit == (center: centerOfMass, satellite: "B")
  echo "ok - asOrbit"

  let exampleInput = """
    COM)B
    B)C
    C)D
    D)E
    E)F
    B)G
    G)H
    D)I
    E)J
    J)K
    K)L
    """

  doAssert directAndIndirectOrbitCount(exampleInput.asOrbitMap) == 42
  echo "ok - directAndIndirectOrbitCount"

  let exampleInput2 = """
    COM)B
    B)C
    C)D
    D)E
    E)F
    B)G
    G)H
    D)I
    E)J
    J)K
    K)L
    K)YOU
    I)SAN
    """.asOrbitMap.asOrbitMapTable
  let yourPathToCOM = exampleInput2.pathToCenterOfMass(you)
  doAssert yourPathToCOM == "K J E D C B".splitWhitespace.toSeq, &"got: {yourPathToCOM}"
  echo "ok - yourPathToCOM"

  let actual = exampleInput2.minOrbitalTransfersRequired(you, santa)
  doAssert actual == 4, &"got: {actual}"
  echo "ok - minOrbitalTransfersRequired"


when isMainModule:
  echo "day 6, part 1:"
  let om = readFile("input/day6.txt").asOrbitMap
  echo &"\torbitCount: {om.len}"
  let c = directAndIndirectOrbitCount(om)
  echo &"\tdirectAndIndirectOrbitCount: {c}"

  echo "day 6, part 2:"
  let omt = om.asOrbitMapTable
  let minTransfers = omt.minOrbitalTransfersRequired(you, santa)
  echo &"\tminTransfers: {minTransfers}"
