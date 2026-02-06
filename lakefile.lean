import Lake
open Lake DSL

package «Goedel-Prover-V2» where
  -- add package configuration options here

lean_lib «GoedelProverV2» where
  -- add library configuration options here

@[default_target]
lean_exe «goedel-prover-v2» where
  root := `Main
