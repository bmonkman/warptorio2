-- Cleaner version of warptorio combinator using utility functions
local utils = require("lib.lib_entity_utils")

local rtint = utils.rgb(128, 128, 255, 255) -- {r=0.5, g=0.5, b=1, a=1}

-- Create the main warptorio combinator
local combinator_entities = utils.createComplete({
    name = "warptorio-combinator",
    
    entity = {
        type = "constant-combinator",
        base = "constant-combinator",
        properties = {
            enabled = false,
            minable = {
                results = {{type = "item", name = "warptorio-combinator", amount = 1}}
            },
            order = "z",
            icons = {{icon = "__base__/graphics/icons/constant-combinator.png", tint = rtint}},
            icon = nil,
            sprites = {
                east = {
                    layers = {
                        {
                            tint = rtint,
                            filename = "__base__/graphics/entity/combinator/constant-combinator.png",
                            frame_count = 1,
                            height = 52,
                            priority = "high",
                            scale = 1,
                            shift = {0, 0.15625},
                            width = 58,
                            x = 58
                        }
                    }
                }
                -- Add other directions (north, south, west) as needed
            }
        }
    },
    
    item = {
        base = "constant-combinator",
        properties = {
            icons = {{icon = "__base__/graphics/icons/constant-combinator.png", tint = rtint}},
            icon = nil
        }
    },
    
    recipe = {
        base = "constant-combinator",
        properties = {
            enabled = false,
            ingredients = {
                {type = "item", name = "constant-combinator", amount = 10},
                {type = "item", name = "arithmetic-combinator", amount = 10},
                {type = "item", name = "decider-combinator", amount = 10},
                {type = "item", name = "programmable-speaker", amount = 10},
                {type = "item", name = "small-lamp", amount = 10},
                {type = "item", name = "advanced-circuit", amount = 20},
                {type = "item", name = "power-switch", amount = 1}
            }
        }
    }
})

-- Create the alternative combinator (non-minable)
local alt_combinator = utils.createEntity({
    type = "constant-combinator",
    base = "constant-combinator",
    name = "warptorio-alt-combinator",
    properties = {
        enabled = false,
        minable = nil, -- Not minable
        order = "z",
        icons = {{icon = "__base__/graphics/icons/constant-combinator.png", tint = rtint}},
        icon = nil,
        sprites = {
            -- Reuse the same tinted sprites
            east = {
                layers = {
                    {
                        tint = rtint,
                        filename = "__base__/graphics/entity/combinator/constant-combinator.png",
                        frame_count = 1,
                        height = 52,
                        priority = "high",
                        scale = 1,
                        shift = {0, 0.15625},
                        width = 58,
                        x = 58
                    }
                }
            }
        }
    }
})

data:extend(combinator_entities)
data:extend{alt_combinator}

-- Benefits of this approach:
-- 1. Clear separation between main combinator and alt combinator
-- 2. Consistent tinting applied to all sprites
-- 3. Recipe ingredients clearly defined
-- 4. No repetitive table.deepcopy calls
-- 5. Easy to add more combinator variants
