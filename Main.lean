import DocGen4
import Lean
import Cli

open DocGen4 Lean Cli

def getTopLevelModules (p : Parsed) : IO (List String) :=  do
  let topLevelModules := p.variableArgsAs! String |>.toList
  if topLevelModules.length == 0 then
    throw <| IO.userError "No topLevelModules provided."
  return topLevelModules

def runSingleCmd (p : Parsed) : IO UInt32 := do
  let relevantModules := [p.positionalArg! "module" |>.as! String |> String.toName]
  let res ← lakeSetup
  match res with
  | Except.ok ws =>
    let (doc, hierarchy) ← load <| .loadAllLimitAnalysis relevantModules
    IO.println "Outputting HTML"
    let baseConfig := getSimpleBaseContext hierarchy
    htmlOutputResults baseConfig doc ws (p.hasFlag "ink")
    return 0
  | Except.error rc => pure rc

def runIndexCmd (_p : Parsed) : IO UInt32 := do
  let hierarchy ← Hierarchy.fromDirectory Output.basePath
  let baseConfig := getSimpleBaseContext hierarchy
  htmlOutputIndex baseConfig
  return 0

def runGenCoreCmd (_p : Parsed) : IO UInt32 := do
  let res ← lakeSetup
  match res with
  | Except.ok ws =>
    let (doc, hierarchy) ← loadCore
    IO.println "Outputting HTML"
    let baseConfig := getSimpleBaseContext hierarchy
    htmlOutputResults baseConfig doc ws (ink := False) 
    return 0
  | Except.error rc => pure rc

def runDocGenCmd (_p : Parsed) : IO UInt32 := do
  IO.println "You most likely want to use me via Lake now, check my README on Github on how to:"
  IO.println "https://github.com/leanprover/doc-gen4"
  return 0

def singleCmd := `[Cli|
  single VIA runSingleCmd;
  "Only generate the documentation for the module it was given, might contain broken links unless all documentation is generated."

  FLAGS:
    ink; "Render the files with LeanInk in addition"

  ARGS:
    module : String; "The module to generate the HTML for. Does not have to be part of topLevelModules."
]

def indexCmd := `[Cli|
  index VIA runIndexCmd;
  "Index the documentation that has been generated by single."
  ARGS:
    ...topLevelModule : String; "The top level modules this documentation will be for."
]

def genCoreCmd := `[Cli|
  genCore VIA runGenCoreCmd;
  "Generate documentation for the core Lean modules: Init and Lean since they are not Lake projects"
]

def docGenCmd : Cmd := `[Cli|
  "doc-gen4" VIA runDocGenCmd; ["0.1.0"]
  "A documentation generator for Lean 4."

  SUBCOMMANDS:
    singleCmd;
    indexCmd;
    genCoreCmd
]

def main (args : List String) : IO UInt32 :=
  docGenCmd.validate args
