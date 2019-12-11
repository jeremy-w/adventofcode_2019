import strformat
import strutils
import sequtils

const
  Width = 25
  Height = 6
  LayerLen = Width*Height

type
  Pixel = int

proc fewestZeroes(layers: seq[seq[Pixel]]): int =
  var leastZeroes = LayerLen + 1
  var leastIndex = -1
  for i, layer in layers:
    let count = layer.count(0)
    if count < leastZeroes:
      leastIndex = i
      leastZeroes = count
  result = leastIndex

when isMainModule:
  let pixels = readFile("input/day8.txt").mapIt(ord(it) - ord('0'))
  let layerCount = pixels.len div LayerLen
  echo &"we have {layerCount} total layers"
  var layers = newSeqOfCap[seq[Pixel]](layerCount)
  for i in 0 .. layerCount-1:
    let first = LayerLen*i
    let last = first + LayerLen
    let layer = pixels[first..last - 1]
    assert layer.len == LayerLen
    layers.add layer
  let i = fewestZeroes(layers)
  let result = layers[i].count(1) * layers[i].count(2)
  echo "day 8, part 1: ", result
