# Day 12: Orbital Simulation
import math
import sequtils
import strutils

type
  Point = tuple[x, y, z: int]
  Moon = ref object of RootObj
    pos: Point
    vel: Point
  Sim = seq[Moon]

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
  result = Moon(pos: (coords[0], coords[1], coords[2]), vel: (0, 0, 0))

func toSim(text: string): Sim =
  text.splitLines.filterIt(it.startsWith "<").mapIt it.toMoon
#endregion

#region Energy Measurement
func potentialEnergy(m: Moon): int =
  m.pos.x.abs + m.pos.y.abs + m.pos.z.abs

func kineticEnergy(m: Moon): int =
  m.vel.x.abs + m.vel.y.abs + m.vel.z.abs

func totalEnergy(m: Moon): int =
  m.potentialEnergy + m.kineticEnergy

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
  # for each pair of moons
  for left in s:
    for right in s:
      # tweak velocity +/- 1 along each axis to move them closer together
      left.attract(right)

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
#endregion

var sim = readFile("input/day12.txt").toSim
sim.run(steps = 1000)
echo "Total energy: ", sim.totalEnergy
