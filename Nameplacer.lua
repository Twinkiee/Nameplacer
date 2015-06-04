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
local STR_UNIT_LIST_NAME_BOTTOM = "BottomPosList"
local STR_UNIT_LIST_NAME_CHEST = "ChestPosList"
local STR_UNIT_LIST_NAME_CUSTOM = "CustomPosList"
local STR_NAMEPLACER_MAIN_WND = "NameplacerConfigForm"
local STR_UNIT_NAME_INPUT = "UnitNameInput"

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Nameplacer:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  o.tItems = {} -- keep track of all the list items
  o.wndSelectedListItem = nil -- keep track of which list item is currently selected

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
    self.tUnitLists = { STR_UNIT_LIST_NAME_CHEST = self.wndUnitListChest, STR_UNIT_LIST_NAME_BOTTOM = self.wndUnitListBottom, STR_UNIT_LIST_NAME_BOTTOM = self.wndUnitListCustom }
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
  self:PopulateItemList()
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
  local wndUnitList = self.tUnitLists[strUnitListName]
  local tRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitList)

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
    local strUnitName = self.wndTrackedUnits:GetCellText(i, 1)
    if (strUnitName == strUnitName) then
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
-- On unit list row selection change
-------------------------------------------------------------------------
function Nameplacer:OnUnitListSelChange(wndControl, wndHandler, iRow, iCol)
  local strUnitName = wndHandler:GetCellText(iRow, iCol)

  self:UpdateUnitNameInput(strUnitName)
end

function Nameplacer:OnTargetUnitChanged(oTarget)

  local strUnitName = oTarget:GetName()
  self:UpdateUnitNameInput(strUnitName)
end

-----------------------------------------------------------------------------------------------
-- Nameplacer Instance
-----------------------------------------------------------------------------------------------
local NameplacerInst = Nameplacer:new()
NameplacerInst:Init()
