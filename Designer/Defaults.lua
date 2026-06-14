---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb, a)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b, a = a}
end

local function GetPrimaryClassResource(resource, fgColor, bgColor, t1, t2, t3)
  return {
    kind = "bar",
    resource = {kind = "class", resource = resource},
    width = 2,
    height = 0.65,
    scale = 1.5,
    alpha = 1,
    layout = "horizontal",
    direction = "left",
    icon = {show = true, position = "right"},
    foreground = {
      asset = "Cooli: Fade Right",
      color = fgColor,
    },
    background = {
      asset = "Cooli: Solid White",
      color = bgColor,
    },
    border = {
      asset = "Cooli: 1px",
      color = {r = 0, g = 0, b = 0},
    },
    thresholdColors = {
      {limit = 0.7, color = t1 or fgColor},
      {limit = 0.9, color = t2 or fgColor},
      {limit = 1, color = t3 or fgColor},
    }
  }
end

addonTable.Designer.Defaults = {
  Group = {
    kind = "group",
    layout = "horizontal",
    padding = 0.2,
    alpha = 1,
    scale = 1,
    alignment = "CENTER",
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
  ItemIcon = {
    kind = "icon",
    resource = {kind = "item", itemID = 0},
    height = 1, scale = 1, alpha = 1
  },
  EquipmentIcon = {
    kind = "icon",
    resource = {kind = "equipment", equipmentSlot = 0},
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
    ["rage"] = GetPrimaryClassResource("rage", {r = 1, g = 0, b = 0}, GetColor("ff787a", 0.3), GetColor("760002"), GetColor("ff0004"), GetColor("e100ff")),
    ["energy"] = GetPrimaryClassResource("energy", GetColor("ffd21e"), GetColor("7e680f", 0.3)),
    ["mana"] = GetPrimaryClassResource("mana", GetColor("009dff"), GetColor("6ab7ff", 0.3)),
    ["runic-power"] = GetPrimaryClassResource("runic-power", GetColor("009dff"), GetColor("6ab7ff", 0.3)),
    ["fury"] = GetPrimaryClassResource("fury", GetColor("ff6633"), GetColor("ffbe90", 0.3)),
    ["pain"] = GetPrimaryClassResource("pain", {r = 1, g = 0, b = 0}, GetColor("ff787a", 0.3), GetColor("760002"), GetColor("ff0004"), GetColor("e100ff")),
    ["lunar-power"] = GetPrimaryClassResource("lunar-power", GetColor("7bf8ff"), GetColor("4d9b9f", 0.3), GetColor("760002"), GetColor("ff0004"), GetColor("e100ff")),
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
