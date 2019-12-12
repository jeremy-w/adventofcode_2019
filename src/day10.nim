# i think this one is raytracing.
import sequtils
import strformat
import strutils

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

func visibleFrom(m: AsteroidMap, p: Point): int =
  if p.row >= m.nrows or p.col >= m.ncols:
    return -1
  return 0

when defined(test):
  let testMap = """
.#..#
.....
#####
....#
...##""".toAsteroidMap
  doAssert testMap.ncols == 5, &"{testMap}"
  doAssert testMap.nrows == 5, &"{testMap}"
  let tests = @[
    (r: 0, c: 1, vis: 7),
    (r: 0, c: 4, vis: 7),
    (r: 2, c: 0, vis: 6),
  ]
  for t in tests:
    let vis = testMap.visibleFrom((row: t.r.Natural, col: t.c.Natural))
    doAssert vis == t.vis, &"got: {vis} for {t}"

var text = readFile("input/day10.txt")
text.stripLineEnd

let map = text.toAsteroidMap
assert map.stringForDisplay == text

echo &"day 10, part 1"
