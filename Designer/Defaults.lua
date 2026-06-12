---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb, a)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b, a = a}
end

addonTable.Designer.Defaults = {
  Group = {
    kind = "group",
    layout = "horizontal",
    padding = 0.2,
    alpha = 1,
    scale = 1,
    entries = {}
  },
  AuraIcon = {
    kind = "icon",
    resource = {kind = "aura", spellID = 0},
    height = 1, scale = 1, alpha = 1
  },
  AbilityIcon = {
    kind = "icon",
    resource = {kind = "ability", spellID = 0},
    height = 1, scale = 1, alpha = 1
  },
  AuraBar = {
    kind = "bar",
    resource = {kind = "aura", spellID = 0},
    width = 1,
    height = 1,
    scale = 1.5,
    layout = "horizontal",
    direction = "right",
    icon = {show = true, position = "left"},
    alpha = 1,
    foreground = {
      asset = "Cooli: Fade Bottom",
      color = {r = 0, g = 1, b = 0},
    },
    background = {
      asset = "Cooli: Solid White",
      color = GetColor("94ff21", 0.3),
    },
    border = {
      asset = "Cooli: Blizzard Midnight",
      color = {r = 1, g = 1, b = 1},
    },
  },
  ClassResource = {
    ["icicles"] = {
      kind = "bar",
      resource = {kind = "class", resource = "icicles"},
      width = 2,
      height = 0.65,
      scale = 1.5,
      alpha = 1,
      layout = "horizontal",
      direction = "left",
      icon = {show = true, position = "right"},
      foreground = {
        asset = "Cooli: Fade Right",
        color = {r = 0, g = 0, b = 1},
      },
      background = {
        asset = "Cooli: Solid White",
        color = GetColor("6bcbff", 0.3),
      },
      border = {
        asset = "Cooli: 1px",
        color = {r = 0, g = 0, b = 0},
      },
    },
    ["rage"] = {
      kind = "bar",
      resource = {kind = "class", resource = "rage"},
      width = 2,
      height = 0.65,
      scale = 1.5,
      alpha = 1,
      layout = "horizontal",
      direction = "left",
      icon = {show = true, position = "right"},
      foreground = {
        asset = "Cooli: Fade Right",
        color = {r = 1, g = 0, b = 0},
      },
      background = {
        asset = "Cooli: Solid White",
        color = GetColor("ff787a", 0.3),
      },
      border = {
        asset = "Cooli: 1px",
        color = {r = 0, g = 0, b = 0},
      },
      thresholdColors = {
        {limit = 0.7, color = GetColor("760002")},
        {limit = 0.9, color = GetColor("ff0004")},
        {limit = 1, color = GetColor("e100ff")},
      }
    },
    ["stagger"] = {
      kind = "bar",
      resource = {kind = "class", resource = "stagger", options = {multiplier = 1.5}},
      width = 2, --0, -- widest of the entries just above or just below in the layout
      height = 0.65,
      scale = 1.5,
      alpha = 1,
      layout = "horizontal",
      direction = "left",
      icon = {show = true, position = "right"},
      foreground = {
        asset = "Cooli: Fade Bottom",
        color = {r = 0, g = 1, b = 0},
      },
      background = {
        asset = "Cooli: Solid White",
        color = GetColor("6bcbff", 0.3),
      },
      border = {
        asset = "Platy: Round Thin",
        color = {r = 0, g = 0, b = 0},
      },
      thresholdColors = {
        {limit = 0.6, color = {r = 0, g = 1, b = 0}, fadedColor = {r = 0, g = 0.7, b = 0}},
        {limit = 1, color = {r = 1, g = 1, b = 0}, fadedColor = {r = 0.7, g = 0.7, b = 0}},
        {limit = 2, color = {r = 1, g = 0, b = 0}, fadedColor = {r = 0.7, g = 0, b = 0}},
      }
    }
  }
}
