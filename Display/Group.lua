---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.GroupMixin = {}

function addonTable.Display.GroupMixin:OnLoad()
end

function addonTable.Display.GroupMixin:Disable()
end

function addonTable.Display.GroupMixin:Setup(details)
  self.details = details
end
