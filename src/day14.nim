#[
You ask the nanofactory to produce a list of the reactions it can perform that are relevant to this process (your puzzle input). Every reaction turns some quantities of specific input chemicals into some quantity of an output chemical. Almost every chemical is produced by exactly one reaction; the only exception, ORE, is the raw material input to the entire process and is not produced by a reaction.

You just need to know how much ORE you'll need to collect before you can produce one unit of FUEL.

Each reaction gives specific quantities for its inputs and output; reactions cannot be partially run, so only whole integer multiples of these quantities can be used. (It's okay to have leftover chemicals when you're done, though.) For example, the reaction 1 A, 2 B, 3 C => 2 D means that exactly 2 units of chemical D can be produced by consuming exactly 1 A, 2 B and 3 C. You can run the full reaction as many times as necessary; for example, you could produce 10 D by consuming 5 A, 10 B, and 15 C.
]#
import deques
import math
import sequtils
import strformat
import strutils
import tables

echo "== Day 14 =="
echo "-- Part 1 --"

type
  Chemical = string
  Qty = int
  Amt = tuple
    qty: Qty
    chem: Chemical

  Reaction = tuple
    inputs: seq[Amt]
    output: Amt

  Reactions = seq[Reaction]

const
  RawInput = "ORE".Chemical
  Goal = "FUEL".Chemical

#[
Suppose your nanofactory produces the following list of reactions:
]#

func toAmt(str: string): Amt =
  let parts = str.strip.splitWhitespace
  assert parts.len == 2, &"{repr(str)}.toAmt gave {parts.len} parts around ' ' but expected 2"
  (qty: parts[0].parseInt, chem: parts[1])

func toReaction(formula: string): Reaction =
  let parts = formula.split("=>").mapIt(it.strip)
  assert parts.len == 2, &"{repr(formula)}.toReaction found {parts.len} parts around '=>' but expected 2"
  (inputs: parts[0].split(", ").mapIt(it.toAmt), output: parts[1].toAmt)

func toReactions(text: string): seq[Reaction] =
  text
  .splitLines
  .mapIt(it.strip)
  .filterIt(it.contains "=>")
  .mapIt(it.toReaction)

func findTheoreticalOreForUnitFuel(rs: Reactions): float64 =
  var outputToInputs = initTable[Chemical, tuple[qty: int, inputs: seq[Amt]]]()
  for r in rs:
    outputToInputs[r.output.chem] = (qty: r.output.qty, inputs: r.inputs)

  var surplus = initTable[Chemical, float64]()

  var oreUsed = 0.toBiggestFloat
  var queue = initDeque[tuple[qty: float64, chem: Chemical]]()
  queue.addLast (qty: 1.toBiggestFloat, chem: Goal)
  while queue.len > 0:
    var next = queue.popFirst
    # debugEcho "making ", next

    if next.chem == RawInput:
      oreUsed += next.qty
      # debugEcho &"  ore: have now used {oreUsed}"
      continue

    var amtToMake = next.qty
    if surplus.hasKey(next.chem):
      let used = min(surplus[next.chem], amtToMake)
      surplus[next.chem] -= used
      amtToMake -= used
      # debugEcho &"    consuming {used} of surplus of {next.chem}, still need to make {amtToMake}"

    let (amountProducedByOneReaction, inputs) = outputToInputs[next.chem]
    # Messing around with this multiple is pushing me over/under.
    # I'm probably missing something about needing to actually track amounts available or something.
    let multiple = (amtToMake /
        amountProducedByOneReaction.toBiggestFloat)
    let surplusCreated = multiple*amountProducedByOneReaction.toBiggestFloat -
        amtToMake
    # debugEcho &"  running {multiple} times creates surplus of {surplusCreated}"
    let avail = surplus.getOrDefault(next.chem, 0)
    surplus[next.chem] = avail + surplusCreated

    for amt in inputs:
      var qtyNeeded = multiple*amt.qty.toBiggestFloat
      let needed = (qty: qtyNeeded, chem: amt.chem)
      debugEcho "    needs ", needed
      queue.addLast needed
  # debugEcho &"ore used: {oreUsed}"
  return oreUsed

func findOreForUnitFuel(rs: Reactions, fuelUnits: int64 = 1): int64 =
  var outputToInputs = initTable[Chemical, tuple[qty: int, inputs: seq[Amt]]]()
  for r in rs:
    outputToInputs[r.output.chem] = (qty: r.output.qty, inputs: r.inputs)

  var surplus = initTable[Chemical, int64]()

  var oreUsed = 0'i64
  var queue = initDeque[tuple[qty: int64, chem: Chemical]]()
  queue.addLast (qty: fuelUnits, chem: Goal)
  while queue.len > 0:
    var next = queue.popFirst
    # debugEcho "making ", next

    if next.chem == RawInput:
      oreUsed += next.qty
      # debugEcho &"  ore: have now used {oreUsed}"
      continue

    var amtToMake = next.qty
    if surplus.hasKey(next.chem):
      let used = min(surplus[next.chem], amtToMake)
      surplus[next.chem] -= used
      amtToMake -= used
      # debugEcho &"    consuming {used} of surplus of {next.chem}, still need to make {amtToMake}"

    let (amountProducedByOneReaction, inputs) = outputToInputs[next.chem]
    # Messing around with this multiple is pushing me over/under.
    # I'm probably missing something about needing to actually track amounts available or something.
    let multiple = ceil(amtToMake.toBiggestFloat /
        amountProducedByOneReaction.toBiggestFloat).toBiggestInt
    let surplusCreated = multiple*amountProducedByOneReaction - amtToMake
    # debugEcho &"  running {multiple} times creates surplus of {surplusCreated}"
    let avail = surplus.getOrDefault(next.chem, 0)
    surplus[next.chem] = avail + surplusCreated

    for amt in inputs:
      var qtyNeeded = multiple*amt.qty
      let needed = (qty: qtyNeeded, chem: amt.chem)
      # debugEcho "    needs ", needed
      queue.addLast needed
  # debugEcho &"ore used: {oreUsed}"
  return oreUsed

echo "\pExample 1"
const ex1 = """10 ORE => 10 A
1 ORE => 1 B
7 A, 1 B => 1 C
7 A, 1 C => 1 D
7 A, 1 D => 1 E
7 A, 1 E => 1 FUEL""".toReactions
echo &"ex1 is: {ex1}"

#[
The first two reactions use only ORE as inputs; they indicate that you can produce as much of chemical A as you want (in increments of 10 units, each 10 costing 10 ORE) and as much of chemical B as you want (each costing 1 ORE). To produce 1 FUEL, a total of 31 ORE is required: 1 ORE to produce 1 B, then 30 more ORE to produce the 7 + 7 + 7 + 7 = 28 A (with 2 extra A wasted) required in the reactions to convert the B into C, C into D, D into E, and finally E into FUEL. (30 A is produced because its reaction requires that it is created in increments of 10.)

]#

let r1 = ex1.findOreForUnitFuel
doAssert r1 == 31, &"got: {r1}"

#[

Or, suppose you have the following list of reactions:

]#

echo "\pExample 2"
const ex2 = """9 ORE => 2 A
8 ORE => 3 B
7 ORE => 5 C
3 A, 4 B => 1 AB
5 B, 7 C => 1 BC
4 C, 1 A => 1 CA
2 AB, 3 BC, 4 CA => 1 FUEL""".toReactions
echo &"ex2 is: {ex2}"
doAssert ex2.findOreForUnitFuel == 165

#[
The above list of reactions requires 165 ORE to produce 1 FUEL:

    Consume 45 ORE to produce 10 A.
    Consume 64 ORE to produce 24 B.
    Consume 56 ORE to produce 40 C.
    Consume 6 A, 8 B to produce 2 AB.
    Consume 15 B, 21 C to produce 3 BC.
    Consume 16 C, 4 A to produce 4 CA.
    Consume 2 AB, 3 BC, 4 CA to produce 1 FUEL.

Here are some larger examples:
]#

echo "\pExample 3"
let ex3 = """157 ORE => 5 NZVS
    165 ORE => 6 DCFZ
    44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
    12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
    179 ORE => 7 PSHF
    177 ORE => 5 HKGWZ
    7 DCFZ, 7 PSHF => 2 XJWVT
    165 ORE => 2 GPVTF
    3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT""".toReactions.findOreForUnitFuel
doAssert ex3 == 13_312, &"got: {ex3}"

echo "\pExample 4 ~~~"
let ex4 = """
    2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
    17 NVRVD, 3 JNWZP => 8 VPVL
    53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
    22 VJHF, 37 MNCFX => 5 FWMGM
    139 ORE => 4 NVRVD
    144 ORE => 7 JNWZP
    5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
    5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
    145 ORE => 6 MNCFX
    1 NVRVD => 8 CXFTF
    1 VJHF, 6 MNCFX => 4 RFSQX
    176 ORE => 6 VJHF""".toReactions.findOreForUnitFuel
doAssert ex4 == 180697, &"got: {ex4}"

echo "\pExample 5 ~~~"
let ex5 = """
    171 ORE => 8 CNZTR
    7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
    114 ORE => 4 BHXH
    14 VRPVC => 6 BMBT
    6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
    6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
    15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
    13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
    5 BMBT => 4 WPTQ
    189 ORE => 9 KTJDG
    1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
    12 VRPVC, 27 CNZTR => 2 XDBXC
    15 KTJDG, 12 BHXH => 5 XCVML
    3 BHXH, 2 VRPVC => 7 MZWV
    121 ORE => 7 VRPVC
    7 XCVML => 6 RJRHP
    5 BHXH, 4 VRPVC => 5 LTCX""".toReactions.findOreForUnitFuel
doAssert ex5 == 2210736, &"got: {ex5}"

#[
Given the list of reactions in your puzzle input, what is the minimum amount of ORE required to produce exactly 1 FUEL?
]#

const day14 = readFile("input/day14.txt").toReactions
let part1 = day14.findOreForUnitFuel
echo &"ORE per FUEL is: {part1}"

const oneTrillion = 1000000000000
  # let theory = day14.findTheoreticalOreForUnitFuel
# echo &"Theoretical ORE per FUEL is: {theory}, so 1 trillion ore buys you {oneTrillion / theory} fuel"

var fuelGenerated = 7993832'i64
while day14.findOreForUnitFuel(fuelUnits = fuelGenerated) > oneTrillion:
  dec fuelGenerated
  echo fuelGenerated
echo &"we can make {fuelGenerated} fuel with {oneTrillion} ore"
