/-
Copyright (c) 2022 Henrik Böving. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Henrik Böving
-/
import Lean

import DocGen4.Process.Base
import DocGen4.Process.AxiomInfo
import DocGen4.Process.TheoremInfo
import DocGen4.Process.OpaqueInfo
import DocGen4.Process.InstanceInfo
import DocGen4.Process.DefinitionInfo
import DocGen4.Process.ClassInfo
import DocGen4.Process.StructureInfo
import DocGen4.Process.InductiveInfo


namespace DocGen4.Process
namespace DocInfo

open Lean Meta Widget

def getDeclarationRange : DocInfo → DeclarationRange
| axiomInfo i => i.declarationRange
| theoremInfo i => i.declarationRange
| opaqueInfo i => i.declarationRange
| definitionInfo i => i.declarationRange
| instanceInfo i => i.declarationRange
| inductiveInfo i => i.declarationRange
| structureInfo i => i.declarationRange
| classInfo i => i.declarationRange
| classInductiveInfo i => i.declarationRange

def getName : DocInfo → Name
| axiomInfo i => i.name
| theoremInfo i => i.name
| opaqueInfo i => i.name
| definitionInfo i => i.name
| instanceInfo i => i.name
| inductiveInfo i => i.name
| structureInfo i => i.name
| classInfo i => i.name
| classInductiveInfo i => i.name

def getKind : DocInfo → String
| axiomInfo _ => "axiom"
| theoremInfo _ => "theorem"
| opaqueInfo _ => "opaque"
| definitionInfo _ => "def"
| instanceInfo _ => "instance"
| inductiveInfo _ => "inductive"
| structureInfo _ => "structure"
| classInfo _ => "class"
| classInductiveInfo _ => "class"

def getType : DocInfo → CodeWithInfos
| axiomInfo i => i.type
| theoremInfo i => i.type
| opaqueInfo i => i.type
| definitionInfo i => i.type
| instanceInfo i => i.type
| inductiveInfo i => i.type
| structureInfo i => i.type
| classInfo i => i.type
| classInductiveInfo i => i.type

def getArgs : DocInfo → Array Arg
| axiomInfo i => i.args
| theoremInfo i => i.args
| opaqueInfo i => i.args
| definitionInfo i => i.args
| instanceInfo i => i.args
| inductiveInfo i => i.args
| structureInfo i => i.args
| classInfo i => i.args
| classInductiveInfo i => i.args

def getAttrs : DocInfo → Array String
| axiomInfo i => i.attrs
| theoremInfo i => i.attrs
| opaqueInfo i => i.attrs
| definitionInfo i => i.attrs
| instanceInfo i => i.attrs
| inductiveInfo i => i.attrs
| structureInfo i => i.attrs
| classInfo i => i.attrs
| classInductiveInfo i => i.attrs

def getDocString : DocInfo → Option String
| axiomInfo i => i.doc
| theoremInfo i => i.doc
| opaqueInfo i => i.doc
| definitionInfo i => i.doc
| instanceInfo i => i.doc
| inductiveInfo i => i.doc
| structureInfo i => i.doc
| classInfo i => i.doc
| classInductiveInfo i => i.doc

def isBlackListed (declName : Name) : MetaM Bool := do
  match ← findDeclarationRanges? declName with
  | some _ =>
    let env ← getEnv
    pure (declName.isInternal)
    <||> (pure <| isAuxRecursor env declName)
    <||> (pure <| isNoConfusion env declName)
    <||> isRec declName
    <||> isMatcher declName
  -- TODO: Evaluate whether filtering out declarations without range is sensible
  | none => return true

-- TODO: Is this actually the best way?
def isProjFn (declName : Name) : MetaM Bool := do
  let env ← getEnv
  match declName with
  | Name.str parent name =>
    if isStructure env parent then
      match getStructureInfo? env parent with
      | some i =>
        match i.fieldNames.find? (· == name) with
        | some _ => return true
        | none => return false
      | none => panic! s!"{parent} is not a structure"
    else
      return false
  | _ => return false

def ofConstant : (Name × ConstantInfo) → MetaM (Option DocInfo) := fun (name, info) => do
  if ← isBlackListed name then
    return none
  match info with
  | ConstantInfo.axiomInfo i => return some <| axiomInfo (← AxiomInfo.ofAxiomVal i)
  | ConstantInfo.thmInfo i => return some <| theoremInfo (← TheoremInfo.ofTheoremVal i)
  | ConstantInfo.opaqueInfo i => return some <| opaqueInfo (← OpaqueInfo.ofOpaqueVal i)
  | ConstantInfo.defnInfo i =>
    if ← isProjFn i.name then
      return none
    else
      if ← isInstance i.name then
        let info ← InstanceInfo.ofDefinitionVal i
        return some <| instanceInfo info
      else
        let info ← DefinitionInfo.ofDefinitionVal i
        return some <| definitionInfo  info
  | ConstantInfo.inductInfo i =>
    let env ← getEnv
    if isStructure env i.name then
      if isClass env i.name then
        return some <| classInfo (← ClassInfo.ofInductiveVal i)
      else
        return some <| structureInfo (← StructureInfo.ofInductiveVal i)
    else
      if isClass env i.name then
        return some <| classInductiveInfo (← ClassInductiveInfo.ofInductiveVal i)
      else
        return some <| inductiveInfo (← InductiveInfo.ofInductiveVal i)
  -- we ignore these for now
  | ConstantInfo.ctorInfo _ | ConstantInfo.recInfo _ | ConstantInfo.quotInfo _ => return none

def getKindDescription : DocInfo → String
| axiomInfo i => if i.isUnsafe then "unsafe axiom" else "axiom"
| theoremInfo _ => "theorem"
| opaqueInfo i =>
  match i.definitionSafety with
  | DefinitionSafety.safe => "opaque"
  | DefinitionSafety.unsafe => "unsafe opaque"
  | DefinitionSafety.partial => "partial def"
| definitionInfo i => Id.run do
  if i.hints.isAbbrev then
    return "abbrev"
  else
    let mut modifiers := #[]
    if i.isUnsafe then
      modifiers := modifiers.push "unsafe"
    if i.isNonComputable then
      modifiers := modifiers.push "noncomputable"

    modifiers := modifiers.push "def"
    return String.intercalate " " modifiers.toList
| instanceInfo i => Id.run do
  let mut modifiers := #[]
  if i.isUnsafe then
    modifiers := modifiers.push "unsafe"
  if i.isNonComputable then
    modifiers := modifiers.push "noncomputable"

  modifiers := modifiers.push "instance"
  return String.intercalate " " modifiers.toList
| inductiveInfo i => if i.isUnsafe then "unsafe inductive" else "inductive"
| structureInfo _ => "structure"
| classInfo _ => "class"
| classInductiveInfo _ => "class inductive"

end DocInfo

end DocGen4.Process
