import strformat

const first = 245182
const last = 790572

proc isValid(password: int): bool =
  let str = $password
  var areTwoTheSame = false
  var prev = str[0]
  for next in str[1..^1]:
    areTwoTheSame = areTwoTheSame or (next == prev)
    if next < prev:
      return false
    prev = next
  return areTwoTheSame

when defined(test):
  doAssert isValid(111111), "has pair, no decreasing"
  doAssert not isValid(223450), "has decreasing pair"
  doAssert not isValid(123789), "lacks double"
  echo "tests passed"
  quit(QuitSuccess)

var validCnt = 0
var password = last + 1
while password >= first:
  dec password
  if password.isValid:
    inc validCnt

echo fmt"in range {first}-{last}, found valid: {validCnt}"
