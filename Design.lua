---WARNING: This layout is outdated and will _NOT_ work with current code

---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb, a)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b, a = a}
end

addonTable.Design.nativeSize = 40

addonTable.Design.MONK_BREWMASTER = {
  kind = "group",
  layout = "standalone",
  entries = {
    {
      kind = "group",
      layout = "vertical",
      alignment = "center",
      padding = 0.2,
      anchor = {"BOTTOM", "UIParent", "BOTTOM", 0, 200},
      entries = {
        {
          kind = "icons",
          layout = "horizontal",
          direction = "right",
          padding = 0.1,
          scale = 0.8,
          height = 1,
          entries = {
            { kind = "ability", spellID = 116705 },
            { kind = "ability", spellID = 109132 },
            { kind = "ability", spellID = 119381 },
            { kind = "ability", spellID = 322109 },
          },
        },
        {
          kind = "icons",
          layout = "horizontal",
          direction = "right",
          padding = 0.1,
          scale = 1.25,
          height = 1,
          entries = {
            { kind = "ability", spellID = 205523 },
            { kind = "ability", spellID = 121253 },
            { kind = "ability", spellID = 119582 },
          },
        },
        {
          kind = "icons",
          layout = "horizontal",
          direction = "right",
          padding = 0.1,
          scale = 1,
          height = 1,
          entries = {
            { kind = "aura", spellID = 322120 },
            { kind = "aura", spellID = 196736 },
            { kind = "aura", spellID = 450615 },
            { kind = "aura", spellID = 383785 },
          },
        },
      },
    }
  }
}

addonTable.Design.MONK_BREWMASTER_2 = {
  kind = "group",
  layout = "standalone",
  entries = {
    {
      kind = "group",
      layout = "vertical",
      alignment = "center",
      padding = 0.2,
      anchor = {"BOTTOM", "UIParent", "BOTTOM", 0, 200},
      entries = {
        {
          kind = "group",
          layout = "horizontal",
          alignment = "bottom",
          padding = 0.1,
          entries = {
            {
              kind = "icons",
              layout = "horizontal",
              padding = 0.1,
              scale = 0.8,
              height = 1,
              entries = {
                { kind = "ability", spellID = 116705 },
                { kind = "ability", spellID = 109132 },
              },
            },
            {
              kind = "icons",
              layout = "horizontal",
              padding = 0.1,
              scale = 1.25,
              height = 1,
              entries = {
                { kind = "ability", spellID = 205523 },
                { kind = "ability", spellID = 121253 },
                { kind = "ability", spellID = 119582 },
              },
            },
            {
              kind = "icons",
              layout = "horizontal",
              padding = 0.1,
              scale = 0.8,
              height = 1,
              entries = {
                { kind = "ability", spellID = 119381 },
                { kind = "ability", spellID = 322109 },
              },
            },
          }
        },
        {
          kind = "bar",
          resource = {kind = "aura", spellID = 322507},
          width = 1, --0 -- widest of the entries just above or just below in the layout
          height = 1,
          scale = 1.5,
          layout = "horizontal",
          direction = "right",
          icon = {show = true, position = "left"},
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
        {
          kind = "bar",
          resource = {kind = "class", resource = "stagger", options = {multiplier = 1.5}},
          width = 2, --0, -- widest of the entries just above or just below in the layout
          height = 0.65,
          scale = 1.5,
          layout = "horizontal",
          direction = "left",
          icon = {show = true, position = "right"},
          foreground = {
            asset = "Cooli: Fade Bottom",
            color = {r = 0, g = 0, b = 1},
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
        },
        {
          kind = "icons",
          layout = "horizontal",
          padding = 0.1,
          scale = 1,
          height = 1,
          entries = {
            { kind = "aura", spellID = 322120 },
            { kind = "aura", spellID = 196736 },
            { kind = "aura", spellID = 450615 },
            { kind = "aura", spellID = 383785 },
          },
        },
      },
    }
  }
}

addonTable.Design.TEMPORARY_DEFAULT_LAYOUT = {
  [268] = addonTable.Design.MONK_BREWMASTER_2,
}
