function bobmods.lib.create_autoplace(inputs)
-- note: Use size 1 for stone size, 1.5 for iron/copper/coal size, over 2 is untested.
  local autoplace = {control = inputs.name}
  local richness = inputs.richness and inputs.richness or 1
  local size = inputs.size and inputs.size or 1.2
  autoplace.sharpness = 1
  autoplace.richness_multiplier = 12500 * richness
  autoplace.richness_base = 250 * richness
  autoplace.size_control_multiplier = 0.06
  autoplace.peaks = {}
  if inputs.starting_area then
    table.insert(autoplace.peaks,bobmods.lib.autoplace_peak{influence = 0.2})
    table.insert(autoplace.peaks,bobmods.lib.autoplace_peak{influence = 0.65, starting_area = 1, noise = {layer = inputs.name, octaves = -3.5 / size, persistance = 0.4}})
  else
    table.insert(autoplace.peaks,bobmods.lib.autoplace_peak{influence = 0.2, starting_area = 0})
  end
  table.insert(autoplace.peaks,bobmods.lib.autoplace_peak{influence = 0.65, starting_area = 0, noise = {layer = inputs.name, octaves = -3 / size, persistance = 0.45 / size}})
  return autoplace
end


function bobmods.lib.autoplace_peak(inputs)
  local peak = {influence = inputs.influence}
  if inputs.starting_area then
    peak.starting_area_weight_optimal = inputs.starting_area
    peak.starting_area_weight_range = 0
    peak.starting_area_weight_max_range = 2
  end
  if inputs.noise then
    peak.noise_layer = inputs.noise.layer
    peak.noise_octaves_difference = inputs.noise.octaves
    peak.noise_persistence = inputs.noise.persistance
  end
  return peak
end

function bobmods.lib.add_autoplace_peak(inputs)
  table.insert(data.raw.resource[inputs.resource].autoplace.peaks,bobmods.lib.autoplace_peak(inputs))
end



function bobmods.lib.add_item_to_resource(resource, item)
  if data.raw.resource[resource] then
    if data.raw.resource[resource].minable.results == nil then 
      data.raw.resource[resource].minable.results = {}
    end

    if data.raw.resource[resource].minable.result then
      local addit = true
      for i, result in pairs(data.raw.resource[resource].minable.results) do
        if ingredient.name == result then addit = false end
      end
      if addit then table.insert(data.raw.resource[resource].minable.results,{type = "item", name = data.raw.resource[resource].minable.result, amount = 1}) end
      data.raw.resource[resource].minable.result = nil
    end
    table.insert(data.raw.resource[resource].minable.results,bobmods.lib.item(item))
  end
end

function bobmods.lib.stage_counts(stages, mult)
  local stage_counts = {}
  local stage = stages
  while stage > 0 do
    stage = stage - 1
    table.insert(stage_counts, mult * (2^stage))
  end
  return stage_counts
end

function bobmods.lib.ore_sprite(inputs)
  local filename
  local width = 38
  local height = 38
  local frame_count = 4
  local variation_count = 8
  if inputs.width then width = inputs.width end
  if inputs.height then height = inputs.height end
  if inputs.frame_count then frame_count = inputs.frame_count end
  if inputs.variation_count then variation_count = inputs.variation_count end
  if inputs.filename then
    filename = inputs.filename
  else
    filename = "__boblibrary__/graphics/entity/ores/ore-1.png"
    width = 38
    height = 38
    frame_count = 4
    variation_count = 8
    if inputs.sheet == 2 then
      filename = "__boblibrary__/graphics/entity/ores/ore-2.png"
    end
    if inputs.sheet == 3 then
      filename = "__boblibrary__/graphics/entity/ores/ore-3.png"
    end
    if inputs.sheet == 4 then
      filename = "__boblibrary__/graphics/entity/ores/ore-4.png"
    end
    if inputs.sheet == 5 then
      filename = "__boblibrary__/graphics/entity/liquid.png"
      width = 75
      height = 61
      variation_count = 1
    end
  end

  return
  {
    sheet =
    {
      filename = filename,
      priority = "extra-high",
      width = width,
      height = height,
      frame_count = frame_count,
      variation_count = variation_count,
      tint = inputs.tint,
      scale = inputs.scale or 1,
    }
  }
end



function bobmods.lib.create_ore_item(inputs)
  data:extend(
  {
    {
      type = "item",
      name = inputs.name,
      icon = inputs.icon,
      flags = {"goes-to-main-inventory"},
      subgroup = inputs.subgroup and inputs.subgroup or "raw-resource",
      order = "b-d[" .. inputs.name .."]",
      stack_size = inputs.stack_size and inputs.stack_size or 200
    }
  }
  )
end

function bobmods.lib.create_ore_resource(inputs)
  local sprite = {}
  local minimum = 35
  local normal = 350
  if inputs.sprite then
    sprite = inputs.sprite
  end
  sprite.tint = inputs.tint
  if inputs.minimum then
    minimum = inputs.minimum
  elseif inputs.autoplace and inputs.autoplace.richness_base then
    minimum = inputs.autoplace.richness_base /10
  end
  if inputs.normal then
    normal = inputs.normal
  elseif inputs.autoplace and inputs.autoplace.richness_base then
    normal = inputs.autoplace.richness_base
  end
  local sheet = bobmods.lib.ore_sprite(sprite)
  data:extend(
  {
    {
      type = "resource",
      name = inputs.name,
      icon = inputs.icon,
      flags = {"placeable-neutral"},
      category = inputs.category,
      order = "b-d-" .. inputs.name,
      minimum = minimum,
      normal = normal,
      infinite = infinite,
      collision_box = inputs.collision_box or {{ -0.1, -0.1}, {0.1, 0.1}},
      selection_box = inputs.selection_box or {{ -0.5, -0.5}, {0.5, 0.5}},
      stages = sheet,
      stage_counts = bobmods.lib.stage_counts(sheet.sheet.variation_count, inputs.stage_mult or 10),
      map_color = inputs.map_color,
      minable =
      {
        mining_particle = inputs.particle,
        hardness = inputs.hardness or 0.9,
        mining_time = inputs.mining_time or 2,
      },
    }
  }
  )
  if inputs.disable_map_grid then
    data.raw.resource[inputs.name].map_grid = false
  end
end

function bobmods.lib.create_ore_particle(inputs)
data:extend(
{
  {
    type = "particle",
    name = inputs.name,
    flags = {"not-on-map"},
    life_time = 180,
    pictures =
    {
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-1.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 5,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-2.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 7,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-3.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 6,
        height = 7,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-4.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 9,
        height = 8,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-5.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 5,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-6.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 6,
        height = 4,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-7.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 7,
        height = 8,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-8.png",
        priority = "extra-high",
        tint = inputs.tint,
        width = 6,
        height = 5,
        frame_count = 1
      }
    },
    shadows =
    {
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-1.png",
        priority = "extra-high",
        width = 5,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-2.png",
        priority = "extra-high",
        width = 7,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-3.png",
        priority = "extra-high",
        width = 6,
        height = 7,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-4.png",
        priority = "extra-high",
        width = 9,
        height = 8,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-5.png",
        priority = "extra-high",
        width = 5,
        height = 5,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-6.png",
        priority = "extra-high",
        width = 6,
        height = 4,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-7.png",
        priority = "extra-high",
        width = 7,
        height = 8,
        frame_count = 1
      },
      {
        filename = "__boblibrary__/graphics/entity/ores/ore-particle-shadow-8.png",
        priority = "extra-high",
        width = 6,
        height = 5,
        frame_count = 1
      }
    }
  }
}
)
end


function bobmods.lib.add_ore_item(inputs)
  if not inputs.resource.items then inputs.resource.items = {} end
  table.insert(inputs.resource.items,inputs.item)
end

function bobmods.lib.generate_ore_data_stage(inputs)
  if inputs.name then
    if not inputs.particle then
      inputs.particle = inputs.name .. "-particle"
      bobmods.lib.create_ore_particle{name = inputs.particle, tint = inputs.tint}
    end

    if inputs.item and inputs.item.create then
      bobmods.lib.create_ore_item{name = inputs.name, icon = inputs.icon, subgroup = inputs.item.subgroup, stack_size = inputs.item.stack_size}
      bobmods.lib.add_ore_item{resource = inputs, item = {name = inputs.name}}
    end

    if not inputs.autoplace then
      inputs.autoplace = bobmods.lib.create_autoplace{name = inputs.name, starting_area = true, size = 1, richness = 1}
    else
      if inputs.autoplace.create then
        local autoplace = bobmods.lib.create_autoplace{name = inputs.name, starting_area = inputs.autoplace.starting_area, size = inputs.autoplace.size, richness = inputs.autoplace.richness}
        inputs.autoplace = autoplace
      end
    end

    bobmods.lib.create_ore_resource(inputs)

    if inputs.items then
      for i, item in pairs(inputs.items) do
        bobmods.lib.add_item_to_resource(inputs.name, item)
      end
    end
  end
end

function bobmods.lib.generate_ore_updates_stage(inputs)
  if data.raw.resource[inputs.name] then
    data:extend(
    {
      {
        type = "autoplace-control",
        name = inputs.name,
        richness = true,
        order = "b-d-" .. inputs.name
      },
      {
        type = "noise-layer",
        name = inputs.name
      },
    }
    )
    data.raw.resource[inputs.name].autoplace = inputs.autoplace
  end
end

function bobmods.lib.generate_ore(inputs)
  bobmods.lib.generate_ore_data_stage(inputs)
  bobmods.lib.generate_ore_updates_stage(inputs)
end

