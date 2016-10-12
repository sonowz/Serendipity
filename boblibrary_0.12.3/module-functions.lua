function bobmods.lib.add_productivity_limitation(intermediate)
  for i, module in pairs(data.raw.module) do
    if module.limitation then
      table.insert(module.limitation, intermediate)
    end
  end
end

function bobmods.lib.add_productivity_limitations(intermediates)
  for i, module in pairs(data.raw.module) do
    if module.limitation then
      for j, intermediate in pairs(intermediates) do
        table.insert(module.limitation, intermediate)
      end
    end
  end
end
