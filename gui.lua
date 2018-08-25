local Gui = require('stdlib/gui/gui')

function gui_different_setting_error (parent, changes)
  local box = parent.center.add{
    type="frame",
    name="serendipity-different-setting-error",
    direction="vertical"
  }
  box.add{
    type="label",
    name="serendipity-different-setting-error-label1",
    caption="Serendipity mod error",
  }
  box.add{
    type="label",
    name="serendipity-different-setting-error-label2",
    caption="Some of startup settings are different from savefile."
  }
  box.add{
    type="label",
    name="serendipity-different-setting-error-label3",
    caption="Please change these settings (from mod setting) below."
  }
  for setting_name, setting_value in pairs(changes) do
    box.add{
      type="label",
      name="serendipity-different-setting-error-"..setting_name,
      caption=setting_name..": "..setting_value
    }
  end
  box.add{
    type="button",
    name="serendipity-different-setting-error-button",
    caption="Quit"
  }
  box.focus()
  script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "serendipity-different-setting-error-button" then
      event.element.destroy()
      error("please restart.")
    end
  end)
end
