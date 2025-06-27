require("lib/lib")

local reqpth="prototypes/"
--require("technology/warp-technology")
require("sound/sound")
require(reqpth.."data_warptorio-accumulators")
require(reqpth.."data_warptorio-heatpipe")
require(reqpth.."data_warptorio-warpport")
require(reqpth.."data_warptorio-logistics-pipe")
require(reqpth.."data_warptorio-warpstation")
require(reqpth.."data_warpnuke")
require(reqpth.."data_warptorio-warploader")
require(reqpth.."data_warptorio-townportal")
require(reqpth.."data_warptorio-combinator")
require(reqpth.."data_warptorio-warpspider")

--require("data_nauvis_preset")
-- require("prototypes-updates/data_accumulators") -- DISABLED: Replaced with EntityBuilder version in prototypes/data_warptorio-accumulators.lua
require("prototypes-updates/data_warptorio-harvester") -- This would be included here if it weren't for factorioextended ruining the accumulator tables >:|

-- Include prototype data from other mod data
require("data_warptorio")


lib.lua()