import os
import sequtils

# Package

version = "0.1.0"
author = "Jeremy W. Sherman"
description = "Advent of Code 2019"
license = "BlueOak-1.0.0"
srcDir = "src"


# walkFiles and others needing glob are not callable from Nimscript, but walkDir is!
let dayBins = toSeq(walkDir("src", relative = true))
  .mapIt(it.path)
  .filterIt(it.startsWith("day") and it.endsWith(".nim"))
  .mapIt(it.changeFileExt(""))
# Echo does not show up, but files can be written to.
# writeFile("foo", dayBins.join("\L"))
bin = dayBins



# Dependencies

requires "nim >= 1.0.4"
