---@class addonTableCoolinator
local addonTable = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

local textureHeight = 20

local function GetLabelsValuesBackgrounds()
  local labels, values = {}, {}
  local assets = LSM:List("statusbar")

  local height = textureHeight
  local width = addonTable.Assets.BarBordersSize.width * height / addonTable.Assets.BarBordersSize.height

  local allKeys = GetKeysArray(addonTable.Assets.BarBackgrounds)
  table.sort(allKeys)
  for _, key in ipairs(allKeys) do
    local details = addonTable.Assets.BarBackgrounds[key]
    local file = LSM:Fetch("statusbar", key)
    local text = "|T".. file .. ":" .. (height - 1) .. ":" .. (width - 1) .. "|t " .. (key:gsub("Cooli: ", ""))
    if details.isTransparent then
      text = addonTable.Locales.NONE
    end

    table.insert(labels, text)
    table.insert(values, key)
  end

  for _, key in ipairs(assets) do
    if not addonTable.Assets.BarBackgrounds[key] then
      local file = LSM:Fetch("statusbar", key)
      local text = "|T".. file .. ":" .. (height - 1) .. ":" .. (width - 1) .. "|t [Custom] " .. key

      table.insert(labels, text)
      table.insert(values, key)
    end
  end

  return labels, values
end

local function GetLabelsValuesBorders()
  local labels, values = {}, {}
  local assets = LSM:List("ninesliceborder")

  local height = textureHeight

  local allKeys = GetKeysArray(addonTable.Assets.BarBordersSliced)
  table.sort(allKeys)
  for _, key in ipairs(allKeys) do
    local details = addonTable.Assets.BarBordersSliced[key]
    local file = LSM:Fetch("nineslice", LSM:Fetch("ninesliceborder", key).nineslice).file
    local text = "|T".. file .. ":" .. (height - 1) .. ":" .. (height - 1) .. "|t " .. (key:gsub("Cooli: ", ""))
    if details.isTransparent then
      text = addonTable.Locales.NONE
    end

    table.insert(labels, text)
    table.insert(values, key)
  end

  for _, key in ipairs(assets) do
    if not addonTable.Assets.BarBordersSliced[key] then
      local file = LSM:Fetch("nineslice", LSM:Fetch("ninesliceborder", key).nineslice).file
      local text = "|T".. file .. ":" .. (height - 1) .. ":" .. (height - 1) .. "|t [Custom] " .. key

      table.insert(labels, text)
      table.insert(values, key)
    end
  end

  return labels, values
end

local fullBarTextures = {
  label = addonTable.Locales.TEXTURES,
  entries = {
    {
      label = addonTable.Locales.BORDER,
      kind = "dropdown",
      getInitData = function(details)
        return GetLabelsValuesBorders()
      end,
      setter = function(details, value)
        details.border.asset = value
      end,
      getter = function(details)
        return details.border.asset
      end
    },
    {
      label = addonTable.Locales.BORDER_COLOR,
      kind = "colorPicker",
      setter = function(details, value)
        details.border.color = value
      end,
      getter = function(details)
        return details.border.color
      end,
    },
    {
      label = addonTable.Locales.FOREGROUND,
      kind = "dropdown",
      getInitData = function()
        return GetLabelsValuesBackgrounds()
      end,
      setter = function(details, value)
        details.foreground.asset = value
      end,
      getter = function(details)
        return details.foreground.asset
      end
    },
    {
      label = addonTable.Locales.FOREGROUND_COLOR,
      kind = "colorPicker",
      setter = function(details, value)
        details.foreground.color = value
      end,
      getter = function(details)
        return details.foreground.color
      end,
    },
    {
      label = addonTable.Locales.BACKGROUND,
      kind = "dropdown",
      getInitData = function()
        return GetLabelsValuesBackgrounds()
      end,
      setter = function(details, value)
        details.background.asset = value
      end,
      getter = function(details)
        return details.background.asset
      end
    },
    {
      label = addonTable.Locales.BACKGROUND_COLOR,
      kind = "colorPicker",
      setter = function(details, value)
        details.background.color = value
      end,
      getter = function(details)
        return details.background.color
      end,
    },
  }
}
local barTextureNoForegroundColor = {
  label = addonTable.Locales.TEXTURES,
  entries = {
    {
      label = addonTable.Locales.BORDER,
      kind = "dropdown",
      getInitData = function(details)
        return GetLabelsValuesBorders()
      end,
      setter = function(details, value)
        details.border.asset = value
      end,
      getter = function(details)
        return details.border.asset
      end
    },
    {
      label = addonTable.Locales.BORDER_COLOR,
      kind = "colorPicker",
      setter = function(details, value)
        details.border.color = value
      end,
      getter = function(details)
        return details.border.color
      end,
    },
    {
      label = addonTable.Locales.FOREGROUND,
      kind = "dropdown",
      getInitData = function()
        return GetLabelsValuesBackgrounds()
      end,
      setter = function(details, value)
        details.foreground.asset = value
      end,
      getter = function(details)
        return details.foreground.asset
      end
    },
    {
      label = addonTable.Locales.BACKGROUND,
      kind = "dropdown",
      getInitData = function()
        return GetLabelsValuesBackgrounds()
      end,
      setter = function(details, value)
        details.background.asset = value
      end,
      getter = function(details)
        return details.background.asset
      end
    },
    {
      label = addonTable.Locales.BACKGROUND_COLOR,
      kind = "colorPicker",
      setter = function(details, value)
        details.background.color = value
      end,
      getter = function(details)
        return details.background.color
      end,
    },
  }
}

addonTable.Designer.WidgetConfiguration = {
  ["icon"] = {
    ["*"] = {
      ["*"] = {
        {
          label = addonTable.Locales.GENERAL,
          entries = {
            {
              label = addonTable.Locales.SCALE,
              kind = "slider",
              min = 25, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.scale = value / 100
              end,
              getter = function(details)
                return details.scale * 100
              end,
            },
            {
              label = addonTable.Locales.TRANSPARENCY,
              kind = "slider",
              min = 0, max = 100,
              formatter = function(value) return value .. "%" end,
              setter = function(details, value)
                details.alpha = 1 - value / 100
              end,
              getter = function(details)
                return (1 - details.alpha) * 100
              end,
            },
          }
        }
      }
    }
  },
  ["bar"] = {
    ["*"] = {
      ["*"] = {
        {
          label = addonTable.Locales.GENERAL,
          entries = {
            {
              label = addonTable.Locales.SCALE,
              kind = "slider",
              min = 25, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.scale = value / 100
              end,
              getter = function(details)
                return details.scale * 100
              end,
            },
            {
              label = addonTable.Locales.TRANSPARENCY,
              kind = "slider",
              min = 0, max = 100,
              formatter = function(value) return value .. "%" end,
              setter = function(details, value)
                details.alpha = 1 - value / 100
              end,
              getter = function(details)
                return (1 - details.alpha) * 100
              end,
            },
            { kind = "spacer" },
            {
              label = addonTable.Locales.HEIGHT,
              kind = "slider",
              min = 50, max = 300,
              formatter = function(value) return value .. "%" end,
              setter = function(details, value)
                details.height = value / 100
              end,
              getter = function(details)
                return details.height * 100
              end,
            },
            {
              label = addonTable.Locales.WIDTH,
              kind = "slider",
              min = 50, max = 300,
              formatter = function(value) return value .. "%" end,
              setter = function(details, value)
                details.width = value / 100
              end,
              getter = function(details)
                return details.width * 100
              end,
            },
            {
              label = addonTable.Locales.LAYOUT,
              kind = "dropdown",
              getInitData = function()
                return {
                  addonTable.Locales.VERTICAL,
                  addonTable.Locales.HORIZONTAL,
                }, {
                  "vertical",
                  "horizontal"
                }
              end,
              setter = function(details, value)
                details.layout = value
              end,
              getter = function(details)
                return details.layout
              end,
            },
          },
        },
      },
    },
    ["aura"] = {
      ["*"] = {
        fullBarTextures,
      },
    },
    ["class"] = {
      ["icicles"] = {
        fullBarTextures
      },
      ["stagger"] = {
        barTextureNoForegroundColor,
        {
          label = addonTable.Locales.THRESHOLDS,
          entries = {
            {
              label = addonTable.Locales.SAFE,
              kind = "slider",
              min = 0, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[1].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[1].limit * 100
              end,
            },
            {
              label = addonTable.Locales.SAFE_COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[1].color = value
              end,
              getter = function(details)
                return details.thresholdColors[1].color
              end,
            },
            {
              label = addonTable.Locales.SAFE_COLOR_FADED,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[1].fadedColor = value
              end,
              getter = function(details)
                return details.thresholdColors[1].fadedColor
              end,
            },
            {
              label = addonTable.Locales.WARNING,
              kind = "slider",
              min = 0, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[2].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[2].limit * 100
              end,
            },
            {
              label = addonTable.Locales.WARNING_COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[2].color = value
              end,
              getter = function(details)
                return details.thresholdColors[2].color
              end,
            },
            {
              label = addonTable.Locales.WARNING_COLOR_FADED,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[2].fadedColor = value
              end,
              getter = function(details)
                return details.thresholdColors[2].fadedColor
              end,
            },
            {
              label = addonTable.Locales.DANGER,
              kind = "slider",
              min = 0, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[3].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[3].limit * 100
              end,
            },
            {
              label = addonTable.Locales.DANGER_COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[3].color = value
              end,
              getter = function(details)
                return details.thresholdColors[3].color
              end,
            },
            {
              label = addonTable.Locales.DANGER_COLOR_FADED,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[3].fadedColor = value
              end,
              getter = function(details)
                return details.thresholdColors[3].fadedColor
              end,
            },
          }
        },
      },
      ["rage"] = {
        barTextureNoForegroundColor,
        {
          label = addonTable.Locales.THRESHOLDS,
          entries = {
            {
              label = "1",
              kind = "slider",
              min = 0, max = 100,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[1].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[1].limit * 100
              end,
            },
            {
              label = addonTable.Locales.COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[1].color = value
              end,
              getter = function(details)
                return details.thresholdColors[1].color
              end,
            },
            {
              label = "2",
              kind = "slider",
              min = 0, max = 100,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[2].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[2].limit * 100
              end,
            },
            {
              label = addonTable.Locales.COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[2].color = value
              end,
              getter = function(details)
                return details.thresholdColors[2].color
              end,
            },
            {
              label = "3",
              kind = "slider",
              min = 0, max = 100,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.thresholdColors[3].limit = value / 100
              end,
              getter = function(details)
                return details.thresholdColors[3].limit * 100
              end,
            },
            {
              label = addonTable.Locales.COLOR,
              kind = "colorPicker",
              setter = function(details, value)
                details.thresholdColors[3].color = value
              end,
              getter = function(details)
                return details.thresholdColors[3].color
              end,
            },
          }
        },
      },
    }
  },
  ["group"] = {
    ["*"] = {
      ["*"] = {
        {
          label = addonTable.Locales.GENERAL,
          entries = {
            {
              label = addonTable.Locales.SCALE,
              kind = "slider",
              min = 25, max = 400,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.scale = value / 100
              end,
              getter = function(details)
                return details.scale * 100
              end,
            },
            {
              label = addonTable.Locales.LAYOUT,
              kind = "dropdown",
              getInitData = function()
                return {
                  addonTable.Locales.VERTICAL,
                  addonTable.Locales.HORIZONTAL,
                }, {
                  "vertical",
                  "horizontal"
                }
              end,
              setter = function(details, value)
                details.layout = value
              end,
              getter = function(details)
                return details.layout
              end,
            },
            {
              label = addonTable.Locales.TRANSPARENCY,
              kind = "slider",
              min = 0, max = 100,
              formatter = function(value) return value .. "%" end,
              setter = function(details, value)
                details.alpha = 1 - value / 100
              end,
              getter = function(details)
                return (1 - details.alpha) * 100
              end,
            },
            {
              label = addonTable.Locales.PADDING,
              kind = "slider",
              min = 0, max = 200,
              valuePattern = "%d%%",
              setter = function(details, value)
                details.padding = value / 100
              end,
              getter = function(details)
                return details.padding * 100
              end,
            },
          }
        }
      }
    }
  }
}
