# Day 12: Orbital Simulation
import math
import sequtils
import strformat
import strutils

# build with --profiler:on --stacktrace:on
# applyGravity, attract, and applyVelocity are now the hotspots.
# Makes sense.
# import nimprof

type
  Point = array[3, int]
  Moon = ref object of RootObj
    pos: Point
    vel: Point
  Sim = array[4, Moon]

template x(p: Point): int = p[0]
template y(p: Point): int = p[1]
template z(p: Point): int = p[2]

func toSeq(p: Point): seq[int] =
  @[p.x, p.y, p.z]

proc `$`(m: Moon): string =
  var maxDigits = max(m.pos.toSeq.mapIt(len($it)).max, m.vel.toSeq.mapIt(len($it)).max)
  result = "pos=<"
  var parts = newSeq[string]()
  for (val, comp) in m.pos.toSeq.zip("xyz"):
    parts.add(&"{comp}={alignString($val, maxDigits, align = '>')}")
  result.add(parts.join(", "))
  result.add(">, vel=<")
  parts.setLen(0)
  for (val, comp) in m.vel.toSeq.zip("xyz"):
    parts.add(&"{comp}={alignString($val, maxDigits, align = '>')}")
  result.add(parts.join(", "))
  result.add(">")

#region Parsing
func toMoon(line: string): Moon =
  let coords = line
    # <x=-13, y=14, z=-7>
  .strip(chars = {'<', '>'})
    # x=-13, y=14, z=-7
    .split(", ")
    # ["x=-13", "y=14", "z=-7"]
    .mapIt(it.split("=")[1])
    # ["-13", "14", "-7"]
    .mapIt(it.parseInt)
  # TODO: Isn't there some way to turn a seq into a tuple?
  result = Moon(pos: [coords[0], coords[1], coords[2]], vel: [0, 0, 0])

func toSim(text: string): Sim =
  for i, m in text.splitLines.filterIt(it.startsWith "<").mapIt(it.toMoon):
    result[i] = m
#endregion

#region Energy Measurement
func potentialEnergy(m: Moon): int =
  m.pos.x.abs + m.pos.y.abs + m.pos.z.abs

func kineticEnergy(m: Moon): int =
  m.vel.x.abs + m.vel.y.abs + m.vel.z.abs

func totalEnergy(m: Moon): int =
  m.potentialEnergy * m.kineticEnergy

func totalEnergy(s: Sim): int =
  s.mapIt(it.totalEnergy).sum
#endregion

#region Simulation
func attract(m1: Moon, m2: Moon) =
  # TODO: How to generalize this? It's the same thing applied at 3 different components of a tuple.
  if m1.pos.x < m2.pos.x:
    m1.vel.x += 1
    m2.vel.x -= 1
  elif m2.pos.x < m1.pos.x:
    m2.vel.x += 1
    m1.vel.x -= 1
  else:
    discard

  if m1.pos.y < m2.pos.y:
    m1.vel.y += 1
    m2.vel.y -= 1
  elif m2.pos.y < m1.pos.y:
    m2.vel.y += 1
    m1.vel.y -= 1
  else:
    discard

  if m1.pos.z < m2.pos.z:
    m1.vel.z += 1
    m2.vel.z -= 1
  elif m2.pos.z < m1.pos.z:
    m2.vel.z += 1
    m1.vel.z -= 1
  else:
    discard

func applyGravity(s: var Sim) =
  for i in countdown(s.high, s.low+1):
    # for each pair of moons
    let m = s[i]
    for j in countup(s.low, i - 1):
      # tweak velocity +/- 1 along each axis to move them closer together
      let m2 = s[j]
      m.attract(m2)

func applyVelocity(m: Moon): Moon =
  # TODO: How to generalize this? It's the same operation applied across a pair of matching components.
  # Returns Moon so we can applyIt in-place.
  m.pos.x += m.vel.x
  m.pos.y += m.vel.y
  m.pos.z += m.vel.z
  return m

func step(s: var Sim) =
  s.applyGravity
  s.applyIt it.applyVelocity

func run(s: var Sim, steps: int) =
  for i in countup(1, steps):
    s.step()

func findStepsTillRepeatedState(s: var Sim): BiggestUint =
  # Internet points out that this reaches a still point then runs backwards.
  # So find the next still point (all zero velocity), double that, and done.
  # We can also just run each axis independently, then find the least-common-multiple.
  s.step
  var stepCnt = 1.BiggestUint
  while not s.allIt(it.vel == [0, 0, 0]):
    s.step
    inc stepCnt
  return stepCnt * 2

func findStepsTillRepeatedStateForComponent(s: var Sim, c: int): BiggestUint =
  var pos: array[4, int]
  var vel: array[4, int]
  for i, m in s:
    pos[i] = m.pos[c]
    vel[i] = m.vel[c]

  func applyGravity() =
    for i in countdown(s.high, s.low+1):
      # for each pair of moons
      let mi = pos[i]
      for j in countup(s.low, i - 1):
        # tweak velocity +/- 1 along each axis to move them closer together
        let mj = pos[j]
        # Apply attraction
        if mi < mj:
          vel[i] += 1
          vel[j] -= 1
        elif mj < mi:
          vel[j] += 1
          vel[i] -= 1
        else:
          continue

  func applyVelocity() =
    for i, v in vel:
      pos[i] += v

  func mstep() =
    applyGravity()
    applyVelocity()

  var stepCnt = 1.BiggestUint
  mstep()
  let target = repeat(0, 4)
  while vel != target:
    mstep()
    inc stepCnt
  return stepCnt * 2


func altFindSteps(s: var Sim): BiggestUint =
  var x = findStepsTillRepeatedStateForComponent(s, 0)
  debugEcho "steps for x: ", x
  var y = findStepsTillRepeatedStateForComponent(s, 1)
  debugEcho "steps for y: ", y
  var z = findStepsTillRepeatedStateForComponent(s, 2)
  debugEcho "steps for z: ", z
  return x.lcm(y).lcm(z)
#endregion

when defined(test):
  let moon = Moon(pos: [1, 2, 3], vel: [0, 0, 0])
  moon.attract(moon)
  doAssert moon.vel == [0, 0, 0], "got: {moon}"
  echo "ok - attracting same makes no change"

  doAssert moon.applyVelocity.pos == [1, 2, 3]
  echo "ok - applying 0 vel does not change pos"

  moon.vel = [1, 2, 3]
  doAssert moon.applyVelocity.pos == [2, 4, 6]
  echo "ok - apply velocity works"

  moon.pos = [3, 0, 0]
  moon.vel = [0, 0, 0]
  let moon2 = Moon(pos: [5, 0, 0], vel: [0, 0, 0])
  moon.attract(moon2)
  doAssert moon.vel == [1, 0, 0]
  doAssert moon2.vel == [-1, 0, 0]
  echo "ok - attracting two different moons works"

  moon.pos = [1, 2, 3]
  moon.vel = [-2, 0, 3]
  doAssert moon.applyVelocity.pos == [-1, 2, 6]
  echo "ok - example velocity application works"

  proc mkPoint(t: tuple[x, y, z: int]): Point = [t.x, t.y, t.z]

  echo "testing: example 1"
  var ex1 = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>""".toSim
  doAssert ex1.len == 4
  ex1.run(0)
  doAssert ex1.mapIt(it.pos) ==
    @[mkPoint((x: -1, y: 0, z: 2)),
    mkPoint((x: 2, y: -10, z: -7)),
    mkPoint((x: 4, y: -8, z: 8)),
    mkPoint((x: 3, y: 5, z: -1))], &"got: {ex1}"
  doAssert ex1.mapIt(it.vel) ==
      @[mkPoint((x: 0, y: 0, z: 0)),
      mkPoint((x: 0, y: 0, z: 0)),
      mkPoint((x: 0, y: 0, z: 0)),
      mkPoint((x: 0, y: 0, z: 0))], &"got: {ex1}"
  echo "ok - 0 steps"

  ex1.run(1)
  doAssert ex1.mapIt(it.vel) ==
    @[mkPoint((x: 3, y: -1, z: -1)),
    mkPoint((x: 1, y: 3, z: 3)),
    mkPoint((x: -3, y: 1, z: -3)),
    mkPoint((x: -1, y: -3, z: 1))], &"got: {ex1}"
  doAssert ex1.mapIt(it.pos) ==
      @[mkPoint((x: 2, y: -1, z: 1)),
      mkPoint((x: 3, y: -7, z: -4)),
      mkPoint((x: 1, y: -7, z: 5)),
      mkPoint((x: 2, y: 2, z: 0))], &"got: {ex1}"
  echo "ok - 1 step"

  ex1.run(1)
  var pic = ex1.join("\L")
  doAssert pic == """
pos=<x= 5, y=-3, z=-1>, vel=<x= 3, y=-2, z=-2>
pos=<x= 1, y=-2, z= 2>, vel=<x=-2, y= 5, z= 6>
pos=<x= 1, y=-4, z=-1>, vel=<x= 0, y= 3, z=-6>
pos=<x= 1, y=-4, z= 2>, vel=<x=-1, y=-6, z= 2>""", &"got: {pic}"
  echo "ok - 2 steps"

  ex1.run(8)
  pic = ex1.join("\L")
  doAssert pic == """
pos=<x= 2, y= 1, z=-3>, vel=<x=-3, y=-2, z= 1>
pos=<x= 1, y=-8, z= 0>, vel=<x=-1, y= 1, z= 3>
pos=<x= 3, y=-6, z= 1>, vel=<x= 3, y= 2, z=-3>
pos=<x= 2, y= 0, z= 4>, vel=<x= 1, y=-1, z=-1>""", &"got: {pic}"
  echo "ok - 10 steps"

  doAssert ex1.totalEnergy == 179, &"got: {ex1.totalEnergy}"

  echo "\L\LPart 2 Tests"
  # the first example above takes 2772 steps before they exactly match a previous point in time;
  # it eventually returns to the initial state
  ex1 = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>""".toSim
  let stepCnt = ex1.altFindSteps
  doAssert stepCnt == 2772, &"got: {stepCnt}"
  echo "ok - small system repeat stepCnt"

echo "== DAY 12 =="
echo "Part 1: Total energy after 1,000 steps"
var sim = readFile("input/day12.txt").toSim
sim.run(steps = 1000)
echo "Total energy: ", sim.totalEnergy

echo "Part 2: Time to repeat"
#[
  Determine the number of steps that must occur
  before all of the moons' positions and velocities
  exactly match a previous point in time.

  Of course, the universe might last for a very long time before repeating.
  You might need to find a more efficient way to simulate the universe.
]#
sim = readFile("input/day12.txt").toSim
let r = sim.altFindSteps
echo "Repeat: ", r
