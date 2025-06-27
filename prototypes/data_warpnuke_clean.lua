-- Cleaner version of warpnuke using utility functions
local utils = require("lib.lib_entity_utils")

local rtint = utils.rgb(102, 102, 255, 255) -- {r=0.4, g=0.4, b=1, a=1}
local nuke_tint = utils.rgb(255, 51, 255, 255) -- {r=1, g=0.2, b=1, a=1}

-- Create warptorio atomic bomb recipe
local atomic_bomb_recipe = utils.createRecipe({
    base = "atomic-bomb",
    name = "warptorio-atomic-bomb",
    properties = {
        enabled = false,
        energy_required = 50,
        ingredients = {
            {type = "item", name = "atomic-bomb", amount = 1},
            {type = "item", name = "warptorio-warponium-fuel-cell", amount = 1},
            {type = "item", name = "warptorio-warponium-fuel", amount = 1}
        }
    }
})

-- Create warptorio atomic bomb ammo item
local atomic_bomb_ammo = utils.createItem({
    base = "atomic-bomb",
    name = "warptorio-atomic-bomb",
    properties = {
        type = "ammo",
        ammo_category = "rocket",
        ammo_type = {
            action = {
                action_delivery = {
                    projectile = "warptorio-atomic-rocket",
                    source_effects = {
                        entity_name = "explosion-hit",
                        type = "create-entity"
                    },
                    starting_speed = 0.05,
                    type = "projectile"
                },
                type = "direct"
            },
            category = "rocket",
            cooldown_modifier = 3,
            range_modifier = 3,
            target_type = "position"
        },
        icons = {{icon = "__base__/graphics/icons/atomic-bomb.png", tint = nuke_tint}},
        icon_size = 64,
        order = "d[rocket-launcher]-c[atomic-bomb]",
        stack_size = 10,
        subgroup = "ammo"
    }
})

-- Create warptorio atomic rocket projectile
local atomic_rocket = utils.createEntity({
    type = "projectile",
    base = "atomic-rocket",
    name = "warptorio-atomic-rocket",
    properties = {
        acceleration = 0,
        action = {
            {
                action_delivery = {
                    target_effects = {
                        {
                            entity_name = "warptorio-explosion",
                            type = "create-entity"
                        }
                    },
                    type = "instant"
                },
                type = "direct"
            }
        },
        animation = {
            filename = "__base__/graphics/entity/rocket/rocket.png",
            frame_count = 8,
            height = 58,
            line_length = 8,
            priority = "high",
            width = 9,
            tint = rtint
        }
    }
})

-- Create the massive explosion effect
local warptorio_explosion = utils.createEntity({
    type = "explosion",
    base = "atomic-bomb-explosion",
    name = "warptorio-explosion",
    properties = {
        animations = {
            {
                filename = "__base__/graphics/entity/atomic-bomb/atomic-bomb-explosion.png",
                flags = {"compressed"},
                frame_count = 47,
                height = 960,
                priority = "very-low",
                scale = 2.0, -- Make it bigger than normal atomic bomb
                width = 960,
                tint = rtint
            }
        },
        -- Enhanced damage for warptorio bomb
        action = {
            action_delivery = {
                target_effects = {
                    {
                        damage = {amount = 2000, type = "explosion"}, -- Double normal atomic bomb
                        type = "damage"
                    },
                    {
                        damage = {amount = 1000, type = "radioactive"},
                        type = "damage"
                    }
                },
                type = "instant"
            },
            type = "direct"
        }
    }
})

data:extend{atomic_bomb_recipe, atomic_bomb_ammo, atomic_rocket, warptorio_explosion}

-- Benefits of this approach:
-- 1. Clear separation of recipe, ammo, projectile, and explosion
-- 2. Easy to modify damage values and effects
-- 3. Consistent tinting and scaling
-- 4. No verbose nested data structures
-- 5. Easy to understand the relationships between components
