-----------------------------------------------------------------------------------------------
-- Client Lua Script for Nameplacer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- Nameplacer Module Definition
-----------------------------------------------------------------------------------------------
local Nameplacer = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloNormal")
local STR_UNIT_LIST_NAME_BOTTOM = "GridBottom"
local STR_UNIT_LIST_NAME_CHEST = "GridChest"
local STR_UNIT_LIST_NAME_CUSTOM = "GridCustom"
local STR_NAMEPLACER_MAIN_WND = "NameplacerConfigForm"
local STR_UNIT_NAME_INPUT = "UnitNameInput"
local STR_UNIT_LIST_SELECTED_BG = "BK3:UI_BK3_Holo_InsetHeader"
local STR_UNIT_LIST_UNSELECTED_BG = "BK3:UI_BK3_Holo_InsetHeader"

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Nameplacer:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  o.tItems = {} -- keep track of all the list items
  o.strSelectedUnitName = nil -- keep track of which unit is currently selected
  o.wndSelectedUnitPosList = nil

  return o
end

function Nameplacer:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {-- "UnitOrPackageName",
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- Nameplacer OnLoad
-----------------------------------------------------------------------------------------------
function Nameplacer:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("Nameplacer.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Nameplacer OnDocLoaded
-----------------------------------------------------------------------------------------------
function Nameplacer:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    self.wndMain = Apollo.LoadForm(self.xmlDoc, STR_NAMEPLACER_MAIN_WND, nil, self)
    if self.wndMain == nil then
      Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
      return
    end

    -- unit lists
    self.wndUnitListChest = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CHEST)
    self.wndUnitListBottom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_BOTTOM)
    self.wndUnitListCustom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CUSTOM)
    self.tUnitLists = { [STR_UNIT_LIST_NAME_CHEST] = self.wndUnitListChest, [STR_UNIT_LIST_NAME_BOTTOM] = self.wndUnitListBottom, [STR_UNIT_LIST_NAME_CUSTOM] = self.wndUnitListCustom }
    self.wndUnitNameInput = self.wndMain:FindChild(STR_UNIT_NAME_INPUT)
    self.wndMain:Show(false, true)

    -- if the xmlDoc is no longer needed, you should set it to nil
    -- self.xmlDoc = nil

    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("nameplacer", "OnNameplacerOn", self)

    Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)


    -- Do additional Addon initialization here
  end
end

-----------------------------------------------------------------------------------------------
-- Nameplacer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/nameplacer"
function Nameplacer:OnNameplacerOn()
  self.wndMain:Invoke() -- show the window

  -- populate the item list
  -- self:PopulateItemList()
end


-----------------------------------------------------------------------------------------------
-- NameplacerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Nameplacer:OnOK()
  self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function Nameplacer:OnCancel()
  self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------
-- Only adds a new row to the units list if the unit is not already present
function Nameplacer:AddUnitRow(strUnitName, strUnitListName)

  Print("strUnitListName: " .. strUnitListName .. "; strUnitName: " .. strUnitName)

  -- local wndUnitList = self.tUnitLists[strUnitListName]
  local wndUnitList = self.wndUnitListChest
  local tRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitList)

  Print("tRowIndex: " .. tostring(tRowIndex))

  if (not tRowIndex) then
    local tRow = wndUnitList:AddRow(strUnitName)
  end
end

------------------------------------------------------------------------
-- Deletes a row from the units list if the unit is actually in the list
------------------------------------------------------------------------
function Nameplacer:DeleteUnitRow(strUnitName, strUnitListName)
  local wndUnitList = self.tUnitLists[strUnitListName]
  local tRowIndex = self:GetRowIndexOfId(id)

  if (tRowIndex) then
    self.wndTrackedUnits:DeleteRow(tRowIndex)
  end
end

------------------------------------------------------------------------
-- Returns the row index for the given units list.
-- Returns nil if the unit is not present or the list is nil
------------------------------------------------------------------------
function Nameplacer:GetUnitRowIndex(strUnitName, strUnitListName)
  local wndUnitList = self.tUnitLists[strUnitListName]

  if (not wndUnitList) then
    return nil
  end

  local tRowIndex

  local trackedUnitCount = wndUnitList:GetRowCount()
  for i = 1, trackedUnitCount do
    local strCurrUnitName = wndUnitList:GetCellText(i, 1)
    if (strUnitName == strCurrUnitName) then
      tRowIndex = i
      return tRowIndex
    end
  end

  return nil
end

------------------------------------------------------------------------
-- populate item list
------------------------------------------------------------------------
function Nameplacer:PopulateItemList()
  -- make sure the item list is empty to start with
  self:DestroyItemList()

  -- add 20 items
  for i = 1, 20 do
    self:AddItem(i)
  end

  -- now all the item are added, call ArrangeChildrenVert to list out the list items vertically
  self.wndItemList:ArrangeChildrenVert()
end

-------------------------------------------------------------------------
-- clear the item list
-------------------------------------------------------------------------
function Nameplacer:DestroyItemList()
  -- destroy all the wnd inside the list
  for idx, wnd in ipairs(self.tItems) do
    wnd:Destroy()
  end

  -- clear the list item array
  self.tItems = {}
  self.wndSelectedListItem = nil
end

-- add an item into the item list
function Nameplacer:AddItem(i)
  -- load the window item for the list item
  local wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)

  -- keep track of the window item created
  self.tItems[i] = wnd

  -- give it a piece of data to refer to
  local wndItemText = wnd:FindChild("Text")
  if wndItemText then -- make sure the text wnd exist
    wndItemText:SetText("item " .. i) -- set the item wnd's text to "item i"
    wndItemText:SetTextColor(kcrNormalText)
  end
  wnd:SetData(i)
end

function Nameplacer:UpdateUnitNameInput(strUnitName)
  self.strSelectedUnitName = strUnitName
  self.wndUnitNameInput:SetText(strUnitName)
end


-------------------------------------------------------------------------
-- On add unit button press
-------------------------------------------------------------------------
function Nameplacer:OnAddUnit()
  local wndUnitNameInput = self.wndUnitNameInput
  local strUnitName = trim(wndUnitNameInput:GetText())

  Print("strUnitName: " .. strUnitName)
  Print("self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_BOTTOM): " .. tostring(self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_BOTTOM)))
  Print("self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CHEST): " .. tostring(self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CHEST)))
  Print("self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CUSTOM): " .. tostring(self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CUSTOM)))

  if (not self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_BOTTOM) and not self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CHEST) and not self:GetUnitRowIndex(strUnitName, STR_UNIT_LIST_NAME_CUSTOM)) then
    self:AddUnitRow(strUnitName, STR_UNIT_LIST_NAME_CHEST)
  end
end

-------------------------------------------------------------------------
-- On unit list row selection change
-------------------------------------------------------------------------
function Nameplacer:OnUnitListSelChange(wndControl, wndHandler, iRow, iCol)
  local strUnitName = wndHandler:GetCellText(iRow, iCol)

  self:UpdateUnitNameInput(strUnitName)
end

function Nameplacer:OnTargetUnitChanged(oTarget)

  if (not oTarget) then return end

  local strUnitName = oTarget:GetName()
  self:UpdateUnitNameInput(strUnitName)
end

---------------------------------------------------------------------------------------------------
-- NameplacerConfigForm Functions
---------------------------------------------------------------------------------------------------
function Nameplacer:OnUnitPosListGainedFocus(wndHandler, wndControl)

  self.wndSelectedUnitPosList = wndHandler

  local wndUnitPosListContainerBackground

  for strUnitPosListName, wndUnitPosList in pairs(self.tUnitLists) do
    local wndCurrUnitPosList = wndControl:FindChild(strUnitPosListName)

    if wndCurrUnitPosList then

      self.wndSelectedUnitPosList = wndCurrUnitPosList
      wndUnitPosListContainerBackground = wndControl:FindChild("Background")
      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_SELECTED_BG)
    else

      local wndUnitPosListContainer = wndUnitPosList:GetParent()
      wndUnitPosListContainerBackground = wndUnitPosListContainer:FindChild("Background")
      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_UNSELECTED_BG)
    end
  end
end

-----------------------------------------------------------------------------------------------
-- Nameplacer Instance
-----------------------------------------------------------------------------------------------
local NameplacerInst = Nameplacer:new()
NameplacerInst:Init()
