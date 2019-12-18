# Advent of Code 2019
Jeremy W. Sherman

Let's go with [Nim](https://nim-lang.org/) this year.

## Getting Started
- Install `choosenim` with the latest stable and the toolchain:

  ```
  > curl https://nim-lang.org/choosenim/init.sh -sSf | sh

  choosenim-init: Downloading choosenim-0.4.0_macosx_amd64
      Prompt: Can choosenim record and send anonymised telemetry data? [y/n]
          ... Anonymous aggregate user analytics allow us to prioritise
          ... fixes and features based on how, where and when people use Nim.
          ... For more details see: https://goo.gl/NzUEPf.
      Answer: y
  Downloading Nim 1.0.4 from nim-lang.org
  [##################################################] 100.0% 0kb/s
   Extracting nim-1.0.4.tar.gz
     Building Nim 1.0.4
     Building tools (nimble, nimgrep, nimpretty, nimsuggest)
    Installed component 'nim'
    Installed component 'nimble'
    Installed component 'nimgrep'
    Installed component 'nimpretty'
    Installed component 'nimsuggest'
     Switched to Nim 1.0.4
  choosenim-init: ChooseNim installed in /Users/jeremy/.nimble/bin
  choosenim-init: You must now ensure that the Nimble bin dir is in your PATH.
  choosenim-init: Place the following line in the ~/.profile or ~/.bashrc file.
  choosenim-init:     export PATH=/Users/jeremy/.nimble/bin:$PATH
  ```

## Handy Tools
- Use `toPrettyProgram` to disassemble an intcode program. You can pass it an array of ranges known to be data so it doesn't desync on opcode parsing.

## Gotcha
I taught Nimble that all my `day*.nim` files are `day*` binaries, but it caches
the targets, so you have to touch the file after adding a new one to get it to
"see" the new binary target.
