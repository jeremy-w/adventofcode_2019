import sequtils
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

proc asOrbit(line: string): Orbit =
  let parts = line.strip.split(isOrbitedBy)
  doAssert parts.len == 2, fmt"bad line: {line}"
  return (center: parts[0], satellite: parts[1])

proc asOrbitMap(lines: string): OrbitMap =
  lines
  .splitLines
  .filterIt(isOrbitedBy in it)
  .mapIt(it.asOrbit)

proc directAndIndirectOrbitCount(om: OrbitMap): int =
  let satelliteToCenterTable = om.mapIt((it.satellite, it.center)).toTable
  for satellite in satelliteToCenterTable.keys:
    var curr = satellite
    while curr != centerOfMass:
      inc result
      curr = satelliteToCenterTable[curr]

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
    """


when isMainModule:
  echo "day 6, part 1:"
  let om = readFile("input/day6.txt").asOrbitMap
  echo &"\torbitCount: {om.len}"
  let c = directAndIndirectOrbitCount(om)
  echo &"\tdirectAndIndirectOrbitCount: {c}"
