--[[-------------------------------------

Author: Pyro-Fire
https://mods.factorio.com/mod/warptorio2

Script: control.lua
Purpose: control stuff

]]---------------------------------------

--[[ Environment ]]--
lib={PLANETORIO=false,REMOTES=true}

-- Add a simple test at the very top
log("Warptorio control.lua is being loaded")

require("lib/lib")
require("control_main")
lib.lua()

