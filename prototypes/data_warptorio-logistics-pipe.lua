local rtint={r=0.5,g=0.5,b=1,a=1}
local rctint=rtint --{r=0.39,g=0,b=0,a=1}

data:extend{

    --[[{
      icons = {{icon="__base__/graphics/icons/pipe-to-ground.png",tint=rtint}},
      icon_size = 32,
      name = "warptorio-logistics-pipe",
      order = "a[pipe]-b[pipe-to-ground]",
      place_result = "warptorio-logistics-pipe",
      stack_size = 50,
      subgroup = "energy-pipe-distribution",
      type = "item"
    }]]

{
      collision_box = {
        {
          -0.29,
          -0.29
        },
        {
          0.29,
          0.2
        }
      },
      corpse = "pipe-remnants",
      --placeable_by={{item="pipe-to-ground",count=1}},
      fast_replaceable_group = "pipe",
      flags = {
        "placeable-neutral",
        "player-creation"
      },
      fluid_box = {
        base_area = 5,
        volume = 100,
        pipe_connections = {
          {
            direction = 0,
            position = {
              0,
              -0.289
            }
          }
        },

        pipe_covers = {
          east = {
            layers = {
              { tint=rctint,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                height = 64,
                priority = "extra-high",
                width = 64,
                scale = 0.5
              },
              {
                draw_as_shadow = true,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                height = 64,
                priority = "extra-high",
                width = 64,
                scale = 0.5
              }
            }
          },
          north = {
            layers = {
              { tint=rctint,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                height = 128,
                priority = "extra-high",
                width = 128,
                scale = 0.75
              },
              {
                draw_as_shadow = true,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                height = 128,
                priority = "extra-high",
                width = 128,
                scale = 0.75
              }
            }
          },
          south = {
            layers = {
              { tint=rctint,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                height = 64,
                priority = "extra-high",
                width = 64,
                scale = 0.75
              },
              {
                draw_as_shadow = true,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                height = 64,
                priority = "extra-high",
                width = 64,
                scale = 0.75
              }
            }
          },
          west = {
            layers = {
              { tint=rctint,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                height = 128,
                priority = "extra-high",
                width = 128,
                scale = 1
              },
              {
                draw_as_shadow = true,
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                height = 128,
                priority = "extra-high",
                width = 128,
                scale = 1
              }
            }
          }
        }
      },
      icon = "__base__/graphics/icons/pipe-to-ground.png",
      icon_size = 32,
      max_health = 150,
      --[[minable = {
        mining_time = 0.1,
        result = "pipe-to-ground"
      }]]
	      order = "a[pipe]-b[pipe-to-ground]",
      name = "warptorio-logistics-pipe",
      pictures = {
        filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-right.png",
        width = 128,
        height = 128,
        priority = "high",
        scale = 0.5,
        down = { tint=rctint,
          filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-down.png",
          height = 128,
          priority = "high",
          width = 128,
          scale = 0.5
        },
        left = { tint=rctint,
          filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-left.png",
          height = 128,
          priority = "high",
          width = 128,
          scale = 0.5
        },
        right = { tint=rctint,
          filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-right.png",
          height = 128,
          priority = "high",
          width = 128,
          scale = 0.5
        },
        up = { tint=rctint,
          filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-up.png",
          height = 128,
          priority = "high",
          width = 128,
          scale = 0.5
        }
      },
      resistances = {
        {
          percent = 80,
          type = "fire"
        },
        {
          percent = 40,
          type = "impact"
        }
      },
      selection_box = {
        {
          -0.5,
          -0.5
        },
        {
          0.5,
          0.5
        }
      },
      type = "pipe-to-ground",
      underground_distance = 10,
      vehicle_impact_sound = {
        filename = "__base__/sound/car-metal-impact.ogg",
        volume = 0.65
      }
    }
}
