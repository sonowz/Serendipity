function bobmods.lib.machine_has_category(machine, category_in)
  local hasit = false
  for i, category in pairs(machine.crafting_categories) do
    if category == category_in then
      hasit = true
    end
  end
  return hasit
end

function bobmods.lib.machine_add_category(machine, category)
  if not bobmods.lib.machine_has_category(machine, category) then
    table.insert(machine.crafting_categories, category)
  end
end

function bobmods.lib.machine_type_if_category_add_category(machine_type, category, category_to_add)
  for i, machine in pairs(data.raw[machine_type]) do
    if bobmods.lib.machine_has_category(machine, category) then
      bobmods.lib.machine_add_category(machine, category_to_add)
    end
  end
end

