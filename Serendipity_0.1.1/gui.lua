function gui_different_seed_error (parent, seed)
  local box = parent.center.add{
    type="frame",
    name="serendipity-different-seed-error",
    direction="vertical"
  }
  box.add{
    type="label",
    name="serendipity-different-seed-error-label1",
    caption="Serendipity mod error",
  }
  box.add{
    type="label",
    name="serendipity-different-seed-error-label2",
    caption="Seed setting is different from savefile seed."
  }
  box.add{
    type="label",
    name="serendipity-different-seed-error-label3",
    caption="Please change seed (from mod setting) to :"..seed
  }
  box.add{
    type="button",
    name="serendipity-different-seed-error-button",
    caption="Quit"
  }
  box.focus()
  script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "serendipity-different-seed-error-button" then
      event.element.destroy()
      error("please restart.")
    end
  end)
end
