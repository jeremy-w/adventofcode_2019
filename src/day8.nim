import strformat
import strutils
import sequtils

const
  Width = 25
  Height = 6
  LayerLen = Width*Height
  Box = '@'

type
  Pixel = int
  Layer = seq[Pixel]
  Image = seq[Layer]

# ACK THE IMAGE IS WHITE ON BLACK, NOT BLACK ON WHITE
const
  Black = 0
  White = 1
  Clear = 2

proc fewestZeroes(layers: Image): int =
  var leastZeroes = LayerLen + 1
  var leastIndex = -1
  for i, layer in layers:
    let count = layer.count(0)
    if count < leastZeroes:
      leastIndex = i
      leastZeroes = count
  result = leastIndex

proc imageString(image: Image; width, height: int): tuple[asText: string;
    asPBM: string] =
  var lines: seq[string]
  var pbmLines: seq[string]
  pbmLines.add "P1"
  pbmLines.add &"{width} {height}"
  for r in 0..height-1:
    var line = ""
    var pbmLine = ""
    for c in 0..width-1:
      for i, layer in image:
        let pixel = layer[r*width + c]
        case pixel
        of Black:
          line.add &" "
          pbmLine.add '0'
          break
        of White:
          line.add &"{Box}"
          pbmLine.add '1'
          break
        of Clear:
          continue
        else:
          continue
    assert line.len == width
    lines.add line
    pbmLines.add pbmLine
  assert lines.len == height
  result = (asText: lines.join("\L"), asPBM: pbmLines.join("\L"))

proc parseLayers(str: string; width, height: int): Image =
  let pixels = str.mapIt(ord(it) - ord('0'))
  let layerLen = width*height
  let layerCount = pixels.len div layerLen
  result = newSeqOfCap[seq[Pixel]](layerCount)
  for i in 0 .. layerCount-1:
    let first = layerLen*i
    let last = first + layerLen
    let layer = pixels[first..last - 1]
    assert layer.len == layerLen
    result.add layer

when isMainModule:
  let layers = readFile("input/day8.txt").parseLayers(width = Width,
      height = Height)
  let i = fewestZeroes(layers)
  let result = layers[i].count(1) * layers[i].count(2)
  echo "day 8, part 1: ", result

echo "checking example image"
let example = "0222112222120000".parseLayers(width = 2, height = 2)
# echo example
assert example.len == 4 # 4 layers
assert example[0].len == 2*2 # 4 pixels per layer
let egImg = example.imageString(2, 2)
  # echo egImg.asText
  # echo egImg.asPBM
assert egImg.asText == &" {Box}\L{Box} "

# Layers are painted in reverse order, so first layer is on top.
let r = imageString(layers, Width, Height)
  # echo r
  # writeFile("day8.pbm", r.asPBM)
echo r.asText
