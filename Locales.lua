---@class addonTableCoolinator
local addonTable = select(2, ...)
local Locales = {
  enUS = {},
  frFR = {},
  deDE = {},
  ruRU = {},
  ptBR = {},
  esES = {},
  esMX = {},
  zhTW = {},
  zhCN = {},
  koKR = {},
  itIT = {},
}

COOLINATOR_LOCALES = Locales

local L = Locales.enUS

L["COOLINATOR"] = "Coolinator"
L["SLASH_DESIGN"] = "design"

L["CUSTOMISE_COOLINATOR"] = "Customise Coolinator"
L["CUSTOMISE_COOLINATOR_X"] = "Customise Coolinator: %s"
L["CTRL_C_TO_COPY"] = "Ctrl+C to copy"
L["JOIN_THE_DISCORD"] = "Join the Discord"
L["DISCORD_DESCRIPTION"] = "Updates, feature suggestions and support"
L["BY_PLUSMOUSE"] = "by plusmouse"
L["DEVELOPMENT_IS_TIME_CONSUMING"] = "|cff04cca4Development takes a huge amount of time|r"
L["DONATE"] = "Donate"
L["LINK"] = "Link"
L["VERSION_COLON_X"] = "Version: %s"
L["TO_OPEN_OPTIONS_X"] = "Access options with /cooli"
L["OPEN_OPTIONS"] = "Open Options"
L["GENERAL"] = "General"
L["TEXTURES"] = "Textures"
L["ENABLE"] = "Enable"
L["DESIGNER"] = "Designer"
L["EDIT_THE_ICONS_AND_BARS_ONSCREEN"] = "Edit the icons and bars onscreen by clicking on them"
L["INCOMPATIBLE_WIDGET_TYPE"] = "Incompatible widget type"
L["BEHAVIOUR"] = "Behaviour"
L["REMOVE_SPACING_FOR_HIDDEN_AURAS"] = "Remove spacing for hidden auras"
L["FADE_WHEN_MOUNTED"] = "Fade when mounted"
L["USE_BLIZZARD_WIDGETS"] = "Use Blizzard widgets (no styling)"
L["SHOW_KEYBINDINGS"] = "Show keybindings"
L["FONT"] = "Font"
L["SHOW_OUTLINE"] = "Show outline"
L["SHOW_SHADOW"] = "Show shadow"
L["ENABLE_IF_LINES_FALLING_OFF_FONT"] = "Enable if lines falling off font"
L["FONT_SIZE"] = "Font size"
L["SHOW_TOOLTIPS"] = "Show tooltips"
L["VISIBLE"] = "Visible"
L["SHOW_FRACTIONS"] = "Show fractions"
L["TEXTS"] = "Texts"
L["SHOW_ICON"] = "Show icon"
L["SHOW_GCD_SWIPE"] = "Show GCD swipe"

L["ENTER_PROFILE_NAME"] = "Enter Profile Name:"
L["PROFILES"] = "Profiles"
L["NEW_PROFILE_CLONE"] = "New Profile (clone current)"
L["NEW_PROFILE_BLANK"] = "New Profile (blank)"
L["CONFIRM_DELETE_PROFILE_X"] = "Are you sure you want to delete profile \"%s\"?"

L["ADD"] = "Add"
L["CHOOSE_A_NEW_DESIGN_NAME"] = "Choose a new design name"
L["INVALID_DESIGN_NAME"] = "Invalid design name"
L["ICON"] = "Icon"
L["GROUP"] = "Group"
L["BAR"] = "Bar"
L["BARS"] = "Bars"
L["AURA"] = "Aura"
L["AURA_BAR"] = "Aura Bar"
L["ABILITY"] = "Ability"
L["ABILITY_BAR"] = "Ability Bar"
L["COOLDOWN"] = "Cooldown"
L["ICICLES"] = "Icicles"
L["TIP_OF_THE_SPEAR"] = "Tip of the spear"
L["UNLEARNED"] = "Unlearned"
L["ITEM"] = "Item"
L["CLASS"] = "Class"
L["INSERT"] = "Insert"
L["CHOOSE_AURA"] = "Choose Aura"
L["CHOOSE_ABILITY"] = "Choose Ability"
L["CHOOSE_POTION_EFFECT"] = "Choose Potion Effect"
L["CHOOSE_ITEM"] = "Choose Item"
L["CHOOSE_EQUIPMENT"] = "Choose Equipment"
L["EQUIPMENT"] = "Equipment"
L["POTION_EFFECT"] = "Potion Effect"
L["WRAP_IN_GROUP"] = "Wrap in group"
L["POPOUT_STANDALONE"] = "Popout (Standalone)"
L["NOTHING_IN_SLOT"] = "Nothing in slot"
L["TOP_LEFT"] = "Top Left"
L["TOP_RIGHT"] = "Top Right"
L["BOTTOM_LEFT"] = "Bottom Left"
L["BOTTOM_RIGHT"] = "Bottom Right"
L["TOP"] = "Top"
L["BOTTOM"] = "Bottom"
L["LEFT"] = "Left"
L["RIGHT"] = "Right"
L["PARENT"] = "Parent"
L["GROW_FROM"] = "Grow from"
L["STYLE"] = "Style"
L["BLIZZARD"] = "Blizzard"
L["SQUARE"] = "Square"
L["CENTER_HORIZONTAL"] = "Center Horizontal"
L["CENTER_VERTICAL"] = "Center Vertical"

L["LAYOUT"] = "Layout"
L["TRANSPARENCY"] = "Transparency"
L["PADDING"] = "Padding"
L["VERTICAL"] = "Vertical"
L["HORIZONTAL"] = "Horizontal"
L["WIDTH"] = "Width"
L["HEIGHT"] = "Height"
L["NONE"] = "None"
L["SCALE"] = "Scale"
L["BORDER"] = "Border"
L["BORDER_COLOR"] = "Border color"
L["READY_BORDER_COLOR"] = "Ready border color"
L["FOREGROUND"] = "Foreground"
L["FOREGROUND_COLOR"] = "Foreground color"
L["BACKGROUND"] = "Background"
L["BACKGROUND_COLOR"] = "Background color"
L["SELECT_GROUP"] = "Select Group"
L["INSERT"] = "Insert"
L["THRESHOLDS"] = "Thresholds"
L["SAFE"] = "Safe"
L["WARNING"] = "Warning"
L["DANGER"] = "Danger"
L["SAFE_COLOR"] = "Safe color"
L["SAFE_COLOR_FADED"] = "Safe color faded"
L["WARNING_COLOR"] = "Warning color"
L["WARNING_COLOR_FADED"] = "Warning color faded"
L["DANGER_COLOR"] = "Danger color"
L["DANGER_COLOR_FADED"] = "Danger color faded"
L["COLOR"] = "Color"
L["SHOW_ICON"] = "Show icon"
L["SHOW_TOOLTIPS"] = "Show tooltips"
L["ICON_POSITION"] = "Icon position"
L["LEFT"] = "Left"
L["RIGHT"] = "Right"
L["CENTER"] = "Center"
L["TOP"] = "Top"
L["BOTTOM"] = "Bottom"
L["ALIGNMENT"] = "Alignment"
L["SHOW_SWIPE"] = "Show swipe"
L["DESATURATE_ON_COOLDOWN"] = "Desaturate on cooldown"

L["PLEASE_RELOAD_TO_GET_COOLINATOR_WORKING_REASON_X"] = "Please reload to get Coolinator working. Reason (%s)"
L["DUE_TO_AURA_BARS_CHANGING_RELOAD_REQUIRED"] = "Due to aura bars changing a reload is required for Coolinator function"

L["OPTIONS"] = "Options"
L["DELETE"] = "Delete"

L["SPEC_MISMATCH_IN_BLIZZARD_CDM"] = "Specialization data mismatch in Blizzard CDM"

L["SLASH_RESET"] = "reset"
L["SLASH_DESIGN"] = "design"
L["SLASH_REGEN"] = "regen"
L["SLASH_RESET_HELP"] = "Reset all Coolinator settings, then reload."
L["SLASH_DESIGN_HELP"] = "Enter/Leave Coolinator Designer mode"
L["SLASH_REGEN_HELP"] = "Start afresh on the current character with your design"
L["SLASH_HELP"] = "Open the Coolinator settings."
L["SLASH_UNKNOWN_COMMAND"] = "Unknown command '%s'"

L["EXPORT"] = "Export"
L["IMPORT"] = "Import"
L["PASTE_YOUR_IMPORT_STRING_HERE"] = "Paste your import string here"

L["WHAT_TO_EXPORT"] = "What to export?"
L["DESIGN"] = "Design"
L["PROFILE"] = "Profile"

L["ENTER_THE_NEW_DESIGN_NAME"] = "Enter the new design name"
L["ENTER_THE_NEW_PROFILE_NAME"] = "Enter the new profile name"
L["THAT_DESIGN_NAME_ALREADY_EXISTS"] = "That style name already exists"
L["THAT_PROFILE_NAME_ALREADY_EXISTS"] = "That profile name already exists"
L["OVERWRITE_CURRENT_PROFILE"] = "Overwrite current profile?"
L["OVERWRITE"] = "Overwrite"
L["MAKE_NEW"] = "Make new"
L["INVALID_IMPORT"] = "Invalid import"
L["NEW_DESIGN"] = "New Design"

L["THANKS_FOR_USING_COOLINATOR_DONATE"] = "Thanks for using Coolinator. Consider donating to support development"

local L = Locales.frFR
--@localization(locale="frFR", format="lua_additive_table")@

local L = Locales.deDE
--@localization(locale="deDE", format="lua_additive_table")@

local L = Locales.ruRU
--@localization(locale="ruRU", format="lua_additive_table")@

local L = Locales.ptBR
--@localization(locale="ptBR", format="lua_additive_table")@

local L = Locales.esES
--@localization(locale="esES", format="lua_additive_table")@

local L = Locales.esMX
--@localization(locale="esMX", format="lua_additive_table")@

local L = Locales.zhTW
--@localization(locale="zhTW", format="lua_additive_table")@

local L = Locales.zhCN
--@localization(locale="zhCN", format="lua_additive_table")@

local L = Locales.koKR
--@localization(locale="koKR", format="lua_additive_table")@

local L = Locales.itIT
--@localization(locale="itIT", format="lua_additive_table")@
