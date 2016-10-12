function bobmods.lib.item (inputs)
  local item = {type = "item"}

  if inputs.name then
    item.name = inputs.name
  else
    item.name = inputs[1]
  end

  if inputs.amount then
    item.amount = inputs.amount
  else
    if inputs[2] then
      item.amount = inputs[2]
    end
  end
  if inputs.amount_min and inputs.amount_max then item.amount_min = inputs.amount_min item.amount_max = inputs.amount_max end
  if not item.amount and not (inputs.amount_min and inputs.amount_max) then item.amount = 1 end
  if inputs.probability then item.probability = inputs.probability end

  if inputs.type then
    item.type = inputs.type
  else
    item.type = bobmods.lib.get_basic_item_type(item.name)
  end

  return item
end

function bobmods.lib.get_item_type(name)
  local item_types = {"ammo", "armor", "capsule", "fluid", "gun", "mining-tool", "module", "tool"}
  local item_type = "item"
  for i, type_name in pairs(item_types) do
    for j, item in pairs(data.raw[type_name]) do
      if item.name == name then item_type = type_name end
    end
  end
  return item_type
end

function bobmods.lib.get_basic_item_type(name)
  local item_types = {"fluid"}
  local item_type = "item"
  for i, type_name in pairs(item_types) do
    for j, item in pairs(data.raw[type_name]) do
      if item.name == name then item_type = type_name end
    end
  end
  return item_type
end

