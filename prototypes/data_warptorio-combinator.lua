local rtint={r=0.5,g=0.5,b=1,a=1}

--[[ Combinator Sprites ]]--

 sprites = {
        east = {
          layers = {
            { tint=rtint,
              filename = "__base__/graphics/entity/combinator/constant-combinator.png",
              frame_count = 1,
              height = 52,
              priority = "high",
              scale = 1,
              shift = {
                0,
                0.15625
              },
              width = 58,
              x = 58
            },
            {
              draw_as_shadow = true,
              filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
              frame_count = 1,
              height = 34,
              priority = "high",
              scale = 1,
              shift = {
                0.28125,
                0.1875
              },
              width = 50,
              x = 50
            }
          }
        },
        north = {
          layers = {
            { tint=rtint,
              filename = "__base__/graphics/entity/combinator/constant-combinator.png",
              frame_count = 1,
              height = 52,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 58,
              x = 0
            },
            {
              draw_as_shadow = true,
              filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
              frame_count = 1,
              height = 34,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 50,
              x = 0
            }
          }
        },
        south = {
          layers = {
            { tint=rtint,
              filename = "__base__/graphics/entity/combinator/constant-combinator.png",
              frame_count = 1,
              height = 52,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 58,
              x = 116
            },
            {
              draw_as_shadow = true,
              filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
              frame_count = 1,
              height = 34,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 50,
              x = 100
            }
          }
        },
        west = {
          layers = {
            { tint=rtint,
              filename = "__base__/graphics/entity/combinator/constant-combinator.png",
              frame_count = 1,
              height = 52,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 58,
              x = 174
            },
            {
              draw_as_shadow = true,
              filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
              frame_count = 1,
              height = 34,
              priority = "high",
              scale = 1,
              shift = nil,
              width = 50,
              x = 150
            }
          }
        }
      }

--[[ Registers ]]--

local name="warptorio-combinator"
local entity = table.deepcopy( data.raw["constant-combinator"]["constant-combinator"] )
entity.name = name
entity.enabled=false
entity.minable.results = {{type="item", name=name, amount=1}}
entity.order="z"
entity.icons={{icon="__base__/graphics/icons/constant-combinator.png",tint=rtint}}
entity.icon=nil
entity.sprites=sprites
local item=table.deepcopy( data.raw.item["constant-combinator"] )
item.name=name item.place_result=name
item.icons={{icon="__base__/graphics/icons/constant-combinator.png",tint=rtint}}
item.icon=nil
local recipe=table.deepcopy( data.raw.recipe["constant-combinator"] )
recipe.enabled=false recipe.name=name 
recipe.results = {
  {
    type = "item",
    name = name,
    amount = 1
  }
}
recipe.ingredients={
  {type="item", name="constant-combinator", amount=10},
  {type="item", name="arithmetic-combinator", amount=10},
  {type="item", name="decider-combinator", amount=10},
  {type="item", name="programmable-speaker", amount=10},
  {type="item", name="small-lamp", amount=10},
  {type="item", name="advanced-circuit", amount=20},
  {type="item", name="power-switch", amount=1}
}

data:extend({entity,item,recipe})

local name="warptorio-alt-combinator"
local entity = table.deepcopy( data.raw["constant-combinator"]["constant-combinator"] )
entity.name = name
entity.enabled=false
entity.minable=nil --.result = name
entity.order="z"
entity.icons={{icon="__base__/graphics/icons/constant-combinator.png",tint=rtint}}
entity.icon=nil
entity.sprites=sprites
local item=table.deepcopy( data.raw.item["constant-combinator"] )
item.name=name item.place_result=name
item.icons={{icon="__base__/graphics/icons/constant-combinator.png",tint=rtint}}
item.icon=nil
local recipe=table.deepcopy( data.raw.recipe["constant-combinator"] )
recipe.enabled=false recipe.name=name 
recipe.results = {
  {
    type = "item",
    name = name,
    amount = 1
  }
}
recipe.ingredients={
  {type="item", name="steel-plate", amount=1}
}

data:extend({entity}) --,item,recipe})
