-- Cleaner version of warptorio warpport using utility functions
local utils = require("lib.lib_entity_utils")

local rtint = utils.rgb(51, 51, 255, 204) -- {r=0.2, g=0.2, b=1, a=0.8}

-- Create warpport using cleaner approach
local warpport_entities = utils.createComplete({
    name = "warptorio-warpport",
    
    entity = {
        type = "roboport",
        base = "roboport",
        properties = {
            icons = {{icon = "__base__/graphics/icons/roboport.png", tint = rtint}},
            icon_size = 64,
            -- Apply tinted graphics
            base = {
                layers = {
                    {
                        tint = rtint,
                        scale = 1/2,
                        filename = "__base__/graphics/entity/roboport/roboport-base.png",
                        height = 135,
                        shift = {0.5/2, 0.25/2},
                        width = 143
                    }
                }
            },
            -- Enhanced capabilities
            construction_radius = 55,
            logistics_radius = 25,
            energy_source = {
                buffer_capacity = "500MJ",
                input_flow_limit = "25MW",
                type = "electric",
                usage_priority = "secondary-input"
            },
            energy_usage = "50kW",
            charging_energy = "2000kW",
            robot_slots_count = 4,
            material_slots_count = 4,
            charging_station_count = 8,
            -- Remove deprecated circuit properties for Factorio 2.0
            circuit_connector_sprites = nil,
            circuit_wire_connection_point = nil,
            circuit_wire_max_distance = 9
        }
    },
    
    item = {
        base = "roboport",
        properties = {
            icons = {{icon = "__base__/graphics/icons/roboport.png", tint = rtint}},
            icon_size = 64,
            order = "c[signal]-a[roboport]",
            stack_size = 10,
            subgroup = "logistic-network"
        }
    },
    
    recipe = {
        base = "roboport",
        properties = {
            enabled = false,
            energy_required = 5,
            ingredients = {
                {type = "item", name = "steel-plate", amount = 45},
                {type = "item", name = "iron-gear-wheel", amount = 45},
                {type = "item", name = "advanced-circuit", amount = 100},
                {type = "item", name = "processing-unit", amount = 100},
                {type = "item", name = "flying-robot-frame", amount = 100},
                {type = "item", name = "roboport", amount = 10},
                {type = "item", name = "warptorio-warponium-fuel", amount = 1}
            }
        }
    }
})

data:extend(warpport_entities)

-- Benefits of this approach:
-- 1. All related data (entity, item, recipe) in one clear structure
-- 2. Automatic Factorio 2.0 compatibility fixes
-- 3. Clear separation of concerns
-- 4. Easy to read and modify
-- 5. Consistent with other entity definitions
