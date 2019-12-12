# i think this one is raytracing.
import algorithm
import math
import sequtils
import sets
import strformat
import strutils
import sugar
import tables

type
  Point* = tuple
    row: Natural
    col: Natural

  AsteroidMap* = tuple
    nrows: Positive
    ncols: Positive
    asteroids: seq[Point]

const
  Asteroid = '#'
  Space = '.'

func toAsteroidMap(text: string): AsteroidMap =
  let rows = text.splitLines
  let nrows = rows.len.Positive
  let ncols = rows[0].len.Positive
  var asteroids: seq[Point]
  for r, row in rows:
    for c, item in row:
      case item
      of Asteroid:
        let point: Point = (row: r.Natural, col: c.Natural)
        asteroids.add point

      of Space:
        continue

      else:
        continue
  result = (nrows: nrows, ncols: ncols, asteroids: asteroids)

func stringForDisplay(m: AsteroidMap): string =
  var rows = newSeqWith(m.nrows, repeat(Space, m.ncols))
  for p in m.asteroids:
    rows[p.row][p.col] = Asteroid
  result = rows.join("\L")

func angle(origin: Point, tail: Point): float64 =
  if origin == tail: return -99
  let dr = tail.row - origin.row
  let dc = tail.col - origin.col
  result = arctan2(dc.float64, dr.float64)

func dist(origin: Point, tail: Point): float64 =
  if origin == tail: return 0
  let dr = float64(tail.row - origin.row)
  let dc = float64(tail.col - origin.col)
  result = dr*dr + dc*dc

func visibleFrom(m: AsteroidMap, p: Point): int =
  if p.row >= m.nrows or p.col >= m.ncols:
    return -1
  var slopes = initHashSet[float]()
  for q in m.asteroids:
    if q == p:
      continue
    let slope = p.angle(q)
    slopes.incl slope
  # debugEcho &"p={p} sees={slopes}"
  return slopes.len

func findAsteroidSeeingMostOthers(m: AsteroidMap): tuple[asteroid: Point, count: int] =
  let counts = m.asteroids.mapIt m.visibleFrom(it)
  let highest = counts.max
  result = (asteroid: m.asteroids[counts.find highest], count: highest)

func findVaporizationOrder(m: AsteroidMap, at: Point): seq[Point] =
  # Given a laser that starts pointing straight up and spins around destroying 1 asteroid per slope, collect the destroyed asteroids in the result.
  const InitAngle = PI # This sure seems like it should be pi/2, but then the tests fail.
  let targets = m.asteroids.filterIt it != at
  type Decorated = tuple[angle: float64, dist: float64, asteroid: Point]
  var labeledTargets = targets
    .mapIt((angle: at.angle(it), dist: at.dist(it), asteroid: it))
    # Sort descending by angle but ascending by distance
    .sorted(
      order = SortOrder.Descending,
      cmp = (left: Decorated, right: Decorated) =>
        cmp((left.angle, -left.dist), (right.angle, -right.dist)))
  debugEcho "labeledTargets: ", labeledTargets.join("\L")

  var initIndex = 0
  block:
    var prevAngle = -Inf
    for i, it in labeledTargets:
      if it.angle >= InitAngle and it.angle != prevAngle:
        initIndex = i
        prevAngle = it.angle

  debugEcho &"InitAngle={InitAngle}, initIndex={initIndex} with {labeledTargets[initIndex]}"
  #debugEcho &"before: {labeledTargets[initIndex - 1]}, after: {labeledTargets[initIndex + 1]}"
  result = newSeqOfCap[Point](targets.len)

  var i = initIndex
  proc wrappingIncr(i: var int) =
    inc i
    if i > labeledTargets.high:
      i = labeledTargets.low

  var prevAngle = -Inf
  while result.len < labeledTargets.len:
    # debugEcho &"{result.len} < {labeledTargets.len}"
    let candidate = labeledTargets[i]
    wrappingIncr i
    let isAlreadyDestroyed = result.contains(candidate.asteroid)
    let isBlocked = prevAngle == candidate.angle
    if isAlreadyDestroyed:
      prevAngle = -Inf
    if not isAlreadyDestroyed and not isBlocked:
      result.add candidate.asteroid
      prevAngle = candidate.angle


when defined(test):
  echo "\L\Ltesting: day10, part1"
  let testMap = """
.#..#
.....
#####
....#
...##""".toAsteroidMap
  doAssert testMap.ncols == 5, &"{testMap}"
  doAssert testMap.nrows == 5, &"{testMap}"
  let counts = @[7, 7, 6, 7, 7, 7, 5, 7, 8, 7]
  for i, a in testMap.asteroids:
    let vis = testMap.visibleFrom(a)
    let c = counts[i]
    doAssert vis == c, &"got: {vis} for {c} at {a}"
    echo &"ok - {i} {a}"
  let best = testMap.findAsteroidSeeingMostOthers
  # Note that their notation is actually (col, row).
  doAssert best.asteroid == (row: 4.Natural, col: 3.Natural), &"got: {best}"
  doAssert best.count == 8

  echo "\L\Ltesting: day10, part2"
  let bigMap = """
.#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##""".toAsteroidMap
  let bigBest = bigMap.findAsteroidSeeingMostOthers
  doAssert bigBest.asteroid == (row: 13.Natural, col: 11.Natural), &"got: {bigBest}"
  doAssert bigBest.count == 210, &"got: {bigBest}"
  let destroyed = bigMap.findVaporizationOrder(at = bigBest.asteroid)
  proc Pt(p: tuple[col: int, row: int]): auto = (row: p.row.Natural,
      col: p.col.Natural)
  doAssert destroyed[0] == (col: 11, row: 12).Pt, &"got: {destroyed[0]}"
  doAssert destroyed[1] == (col: 12, row: 1).Pt, &"got: {destroyed[1]}"
  doAssert destroyed[2] == (col: 12, row: 2).Pt, &"got: {destroyed[2]}"
  doAssert destroyed[10] == (col: 12, row: 8).Pt, &"got: {destroyed[10]}"
  doAssert destroyed[20] == (col: 16, row: 0).Pt, &"got: {destroyed[20]}"
  doAssert destroyed[200] == (col: 8, row: 2).Pt, &"got: {destroyed[200]}"

var text = readFile("input/day10.txt")
text.stripLineEnd

let map = text.toAsteroidMap
assert map.stringForDisplay == text

echo &"day 10, part 1"
let bestLocation = map.findAsteroidSeeingMostOthers
echo &"best location: {bestLocation}"
assert bestLocation == (asteroid: (row: 13.Natural, col: 11.Natural), count: 227)

echo "day 10, part 2"
let order = map.findVaporizationOrder(at = bestLocation.asteroid)
let twoHundredth = order[199]
let answer = 100*twoHundredth.col + twoHundredth.row
echo &"200th asteroid vaporized is: {twoHundredth}, so answer is: {answer}"
