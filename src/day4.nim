import strformat

const first = 245182
const last = 790572

when defined(debug):
  const debug = echo
else:
  template debug(x: varargs[untyped]) = discard


proc isValid(password: int, allowingLargeGroups: bool = true): bool =
  debug &"checking {password} allowingLargeGroups={allowingLargeGroups}"
  let str = $password
  var areTwoTheSame = false
  var prev = str[0]
  var runLength = 1

  proc checkRunLengthOnChange() =
    if allowingLargeGroups and runLength >= 2 or not allowingLargeGroups and
        runLength == 2:
      debug "\t\tfound a valid run length: ", runLength
      areTwoTheSame = true
    runLength = 1

  for next in str[1..^1]:
    debug &"\t{prev}, {next} - runLength {runLength}"
    if not areTwoTheSame and next == prev:
      runLength += 1
    else:
      checkRunLengthOnChange()
    if next < prev:
      debug "\tINVALID: disqualified for decreasing!"
      return false
    prev = next
  checkRunLengthOnChange()
  debug &"\tvalid? {areTwoTheSame}"
  return areTwoTheSame

when defined(test):
  doAssert isValid(111111), "has pair, no decreasing"
  doAssert not isValid(223450), "has decreasing pair"
  doAssert not isValid(123789), "lacks double"
  echo "tests part 1 passed"

  doAssert isValid(112233, false), "valid with larger groups"
  doAssert not isValid(123444, false), "triple 4"
  doAssert isValid(111122, false), "has a single pair still"
  quit(QuitSuccess)

var validCnt = 0
var pairOnlyValidCnt = 0
var password = last + 1
while password >= first:
  dec password
  if password.isValid:
    inc validCnt
  if password.isValid(allowingLargeGroups = false):
    inc pairOnlyValidCnt

# Let's make sure we don't break the known-working output.
doAssert validCnt == 1099

echo fmt"in range {first}-{last}, found valid: {validCnt} and pair-only valid: {pairOnlyValidCnt}"
