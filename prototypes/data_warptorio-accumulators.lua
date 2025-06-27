-- Refactored data_accumulators.lua using the new EntityBuilder library
-- This replaces the messy ExtendDataCopy pattern with a clean, fluent API

require("circuit-connector-sprites")
local EntityBuilder = require("lib.lib_entity_builder")

-- Helper function for RGB colors
local function rgb(r, g, b, a)
    a = a or 255
    return {r = r/255, g = g/255, b = b/255, a = a/255}
end

-- Common configurations
local WARPTORIO_TINT = rgb(153, 153, 255, 153) -- {r=0.6, g=0.6, b=1, a=0.6}
local LAB_ICON = "__base__/graphics/icons/lab.png"
local LAB_PICTURE = "__base__/graphics/entity/lab/lab.png"

-- Create base teleporter (tier 0)
local teleporter_configs = {
    {tier = 0, buffer = "2MJ", input = "200kW", output = "200kW"},
    {tier = 1, buffer = "4MJ", input = "2MW", output = "2MW"},
    {tier = 2, buffer = "8MJ", input = "20MW", output = "20MW"},
    {tier = 3, buffer = "16MJ", input = "200MW", output = "200MW"},
    {tier = 4, buffer = "32MJ", input = "2000MW", output = "2000MW"},
    {tier = 5, buffer = "64MJ", input = "20000MW", output = "20000MW"}
}

-- Create basic teleporter tier 0 (the base for all others)
EntityBuilder.Accumulator:new("accumulator")
    :name("warptorio-teleporter-0")
    :health(500)
    :buffer_capacity("2MJ")
    :flow_limits("200kW", "200kW")
    :property("energy_source", {
        type = "electric",
        usage_priority = "tertiary"
    })
    :icons({{icon = LAB_ICON, tint = WARPTORIO_TINT}})
    :collision_box({{-1.01/0.9, -1.01/0.9}, {1.01/0.9, 1.01/0.9}})
    :selection_box({{-1.5/0.9, -1.5/0.9}, {1.5/0.9, 1.5/0.9}})
    :charge_cooldown(30)
    :discharge_cooldown(60)
    :property("charge_light", {intensity = 0.3, size = 7, color = {r = 1.0, g = 1.0, b = 1.0}})
    :property("discharge_light", {intensity = 0.7, size = 7, color = {r = 1.0, g = 1.0, b = 1.0}})
    :property("default_output_signal", {type = "virtual", name = "signal-A"})
    :property("vehicle_impact_sound", {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65})
    :property("repair_sound", {filename = "__base__/sound/manual-repair-simple.ogg"})
    :property("maximum_wire_distance", 7.5)
    :property("supply_area_distance", 2.5)
    :property("picture", {
        layers = {
            {
                filename = LAB_PICTURE,
                tint = WARPTORIO_TINT,
                width = 194,
                height = 174,
                frame_count = 33,
                animation_speed = 1/3,
                line_length = 11,
                shift = util.by_pixel(0, 1.5),
                scale = 0.45
            }
        }
    })
    :recipe_ingredients({{type = "item", name = "steel-plate", amount = 1}})
    :recipe_enabled(false)
    :build()

-- Create teleporter variants (tiers 1-5)
for i = 2, 6 do
    local config = teleporter_configs[i]
    EntityBuilder.Accumulator:new("warptorio-teleporter-0")
        :name("warptorio-teleporter-" .. config.tier)
        :buffer_capacity(config.buffer)
        :flow_limits(config.input, config.output)
        :build()
end

-- Create teleporter gates
local GATE_TINT = rgb(255, 153, 153, 153) -- {r=1, g=0.6, b=0.6, a=0.6}

EntityBuilder.Accumulator:new("warptorio-teleporter-0")
    :name("warptorio-teleporter-gate-0")
    :icons({{icon = LAB_ICON, tint = GATE_TINT}})
    :property("minable", {mining_time = 0.7, results = {{type = "item", name = "warptorio-teleporter-gate-0", amount = 1}}})
    :build()

-- Create teleporter gate variants
local gate_configs = {
    {tier = 1, buffer = "4MJ", input = "2MW", output = "2MW"},
    {tier = 2, buffer = "8MJ", input = "20MW", output = "20MW"},
    {tier = 3, buffer = "16MJ", input = "200MW", output = "200MW"},
    {tier = 4, buffer = "32MJ", input = "2GW", output = "2GW"},
    {tier = 5, buffer = "64MJ", input = "20GW", output = "20GW"}
}

for _, config in ipairs(gate_configs) do
    EntityBuilder.Accumulator:new("warptorio-teleporter-gate-0")
        :name("warptorio-teleporter-gate-" .. config.tier)
        :buffer_capacity(config.buffer)
        :flow_limits(config.input, config.output)
        :build()
end

-- Create underground/stairway entities
local UNDERGROUND_TINT = rgb(204, 204, 255, 255) -- {r=0.8, g=0.8, b=1, a=1}
local FURNACE_ICON = "__base__/graphics/icons/electric-furnace.png"

EntityBuilder.Accumulator:new("accumulator")
    :name("warptorio-underground-0")
    :health(500)
    :buffer_capacity("2MJ")
    :flow_limits("5MW", "5MW")
    :property("energy_source", {
        type = "electric",
        usage_priority = "tertiary"
    })
    :icons({{icon = FURNACE_ICON, tint = UNDERGROUND_TINT}})
    :collision_box({{-1.01/0.9, -1.01/0.9}, {1.01/0.9, 1.01/0.9}})
    :selection_box({{-1.5/0.9, -1.5/0.9}, {1.5/0.9, 1.5/0.9}})
    :charge_cooldown(30)
    :discharge_cooldown(60)
    :property("charge_light", {intensity = 0.3, size = 7, color = {r = 1.0, g = 1.0, b = 1.0}})
    :property("discharge_light", {intensity = 0.7, size = 7, color = {r = 1.0, g = 1.0, b = 1.0}})
    :property("default_output_signal", {type = "virtual", name = "signal-A"})
    :property("vehicle_impact_sound", {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65})
    :property("repair_sound", {filename = "__base__/sound/manual-repair-simple.ogg"})
    :property("maximum_wire_distance", 7.5)
    :property("supply_area_distance", 2.5)
    :property("picture", {
        layers = {
            {
                tint = UNDERGROUND_TINT,
                scale = 0.45,
                filename = "__base__/graphics/entity/electric-furnace/electric-furnace.png",
                priority = "high",
                width = 129,
                height = 100,
                frame_count = 1,
                shift = {0.421875/2, 0}},
            {
                filename = "__base__/graphics/entity/electric-furnace/electric-furnace-shadow.png",
                draw_as_shadow = true,
                scale = 0.45,
                priority = "high",
                width = 129,
                height = 100,
                frame_count = 1,
                shift = {0.421875, 0}}
        }
    })
    :recipe_ingredients({{type = "item", name = "steel-plate", amount = 1}})
    :recipe_enabled(false)
    :build()

-- Create underground variants
local underground_configs = {
    {tier = 1, buffer = "10MJ", input = "500MW", output = "500MW"},
    {tier = 2, buffer = "50MJ", input = "1GW", output = "1GW"},
    {tier = 3, buffer = "100MJ", input = "2GW", output = "2GW"},
    {tier = 4, buffer = "500MJ", input = "5GW", output = "5GW"},
    {tier = 5, buffer = "1GJ", input = "20GW", output = "20GW"}
}

for _, config in ipairs(underground_configs) do
    EntityBuilder.Accumulator:new("warptorio-underground-0")
        :name("warptorio-underground-" .. config.tier)
        :buffer_capacity(config.buffer)
        :flow_limits(config.input, config.output)
        :build()
end

-- Create warp accumulator
local ACCUMULATOR_TINT = rgb(102, 102, 255, 255) -- {r=0.4, g=0.4, b=1, a=1}

local warp_accumulator = EntityBuilder.Accumulator:new("accumulator")
    :name("warptorio-accumulator")
    :buffer_capacity("1GJ")
    :flow_limits("5GW", "5GW")
    :property("energy_source", {
        emissions_per_minute = {pollution = 5}
    })
    :property("picture", {
        layers = {
            {
                filename = "__base__/graphics/entity/accumulator/accumulator.png",
                tint = ACCUMULATOR_TINT,
                priority = "high",
                width = 66,
                height = 94,
                shift = {0, -0.125},
                scale = 1
            }
        }
    })
    :property("minable", {mining_time = 2, results = {{type = "item", name = "warptorio-accumulator", amount = 1}}})
    :icons({{icon = "__base__/graphics/icons/accumulator.png", tint = ACCUMULATOR_TINT, icon_size = 64}})
    :recipe_ingredients({
        {type = "item", name = "accumulator", amount = 10},
        {type = "item", name = "solar-panel", amount = 10},
        {type = "item", name = "advanced-circuit", amount = 20},
        {type = "item", name = "processing-unit", amount = 50},
        {type = "item", name = "battery", amount = 50},
        {type = "item", name = "nuclear-reactor", amount = 1}
    })
    :recipe_enabled(false)
    :build()

-- Create technology for warp accumulator
EntityBuilder.Technology:new("warptorio-accumulator")
    :upgrade(true)
    :icons({{
        icon = "__base__/graphics/technology/electric-energy-acumulators.png",
        tint = rgb(77, 77, 255, 255), -- {r=0.3, g=0.3, b=1, a=1}
        priority = "low",
        icon_size = 256
    }})
    :research_cost(1000, 5)
    :unlocks_recipe("warptorio-accumulator")
    :prerequisites({"warptorio-energy-4", "warptorio-teleporter-4", "production-science-pack"})
    :science_packs({red = 1, green = 1, blue = 1, purple = 1})
    :build()
