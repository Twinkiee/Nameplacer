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
local STR_UNIT_GRID_NAME_BOTTOM = "GridBottom"
local STR_UNIT_GRID_NAME_CHEST = "GridChest"
local STR_UNIT_GRID_NAME_CUSTOM = "GridCustom"
local STR_UNIT_GRID_NAME = "Grid"
local STR_UNIT_LIST_NAME_BOTTOM = "BottomListContainer"
local STR_UNIT_LIST_NAME_CHEST = "ChestListContainer"
local STR_UNIT_LIST_NAME_CUSTOM = "CustomListContainer"
local STR_NAMEPLACER_MAIN_WND = "NameplacerConfigForm"
local STR_UNIT_NAME_INPUT = "UnitNameInputBox"
local STR_VERTICAL_OFFSET_INPUT = "VerticalOffsetInputBox"
local STR_VERTICAL_OFFSET_CONTAINER = "VerticalOffsetContainer"
local STR_UNIT_LIST_SELECTED_BG = "BK3:UI_BK3_Holo_InsetHeader"
local STR_UNIT_LIST_UNSELECTED_BG = "BK3:UI_BK3_Holo_InsetHeaderThin"
local STR_BTN_FROM_CHEST_TO_BOTTOM = "ButtonFromChestToBottom"
local STR_BTN_FROM_BOTTOM_TO_CHEST = "ButtonFromBottomToChest"
local STR_BTN_FROM_BOTTOM_TO_CUSTOM = "ButtonFromBottomToCustom"
local STR_BTN_FROM_CUSTOM_TO_BOTTOM = "ButtonFromCustomToBottom"
local N_DEFAULT_VERTICAL_OFFSET = 50

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Nameplacer:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  o.tUnits = {} -- keep track of all the list items

  -- keep track of which unit is currently selected
  o.strSelectedUnitName = nil

  -- Main unit position list container
  o.wndSelectedUnitPosList = nil

  return o
end

-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------

------------------------------------------------------------------------
-- Add a new unit to the units list and updates the related grid
------------------------------------------------------------------------
function Nameplacer:AddUnit(strUnitName, wndUnitGrid, nVerticalOffset, bFirsInit)

  local tPostion
  local nNewVerticalOffset = nVerticalOffset

  -- local strUnitGridName = wndUnitGrid:GetName()
  if (wndUnitGrid == self.wndUnitGridChest) then
    tPostion = { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Chest }
  elseif (wndUnitGrid == self.wndUnitGridBottom) then
    tPostion = { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Bottom }
  else
    if (not nNewVerticalOffset) then
      nNewVerticalOffset = N_DEFAULT_VERTICAL_OFFSET
    end

    tPostion = { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Bottom, nVerticalOffset = nNewVerticalOffset }
  end
  self.tUnits[strUnitName] = tPostion

  self:AddUnitRow(strUnitName, wndUnitGrid, nNewVerticalOffset, bFirsInit)
  
  if (not bFirsInit) then
  self:FireEventUnitNameplatePositionChanged(strUnitName, tPostion)
  end

  -- Print(table.tostring(self.tUnits))
end

------------------------------------------------------------------------
-- Add a new row to the units grid and make it selected
------------------------------------------------------------------------
function Nameplacer:AddUnitRow(strUnitName, wndUnitGrid, nVerticalOffset, bUpdateUnitSelection)

  local strGridName = wndUnitGrid:GetName()
  Print("wndUnitGrid: " .. strGridName .. "; strUnitName: " .. strUnitName)

  local nNewRowIndex = wndUnitGrid:AddRow(strUnitName)

  -- Also initializing the vertical offset value
  if (nVerticalOffset) then
    self:UpdateVerticalOffsetCell(nNewRowIndex, nVerticalOffset)
  end

  Print("tRowIndex: " .. tostring(nNewRowIndex))

  if (not bUpdateUnitSelection) then
  self:InitUnitSelection(strUnitName, true)
end
end

------------------------------------------------------------------------
-- Remove a unit from the units list and updates the related grid
------------------------------------------------------------------------
function Nameplacer:DeleteUnit(strUnitName, wndUnitGrid)

  local nRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitGrid)

  if (nRowIndex) then
    self:UpdateUnitNameInput("", true)
    self.tUnits[strUnitName] = nil
    self.strSelectedUnitName = nil
  end

  self:DeleteUnitRow(strUnitName, wndUnitGrid)

  local strCurrentTargetName
  local tPlayer = GameLib.GetPlayerUnit()
  if (tPlayer) then
    local tCurrentTarget = tPlayer:GetTarget()
    if (tCurrentTarget) then
      strCurrentTargetName = tCurrentTarget:GetName()
  end
end
  self:UpdateUnitNameInput(strCurrentTargetName)
end

------------------------------------------------------------------------
-- Deletes a row from the units list if the unit is actually in the list
------------------------------------------------------------------------
function Nameplacer:DeleteUnitRow(strUnitName, wndUnitGrid)
  local nRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitGrid)

  if (nRowIndex) then
    wndUnitGrid:DeleteRow(nRowIndex)
  end

  self:ResetGridSelection()
  return nRowIndex
end

------------------------------------------------------------------------
-- Returns the grid contained by the given list.
------------------------------------------------------------------------
function Nameplacer:FromListToGrid(wndList)
  if (wndList:GetName() == STR_UNIT_LIST_NAME_BOTTOM) then
    return self.wndUnitGridBottom
  elseif (wndList:GetName() == STR_UNIT_LIST_NAME_CHEST) then
    return self.wndUnitGridChest
  else
    return self.wndUnitGridCustom
  end
end

------------------------------------------------------------------------
-- Returns the row index for the given units list.
-- Returns nil if the unit is not present or the list is nil
------------------------------------------------------------------------
function Nameplacer:GetUnitRowIndex(strUnitName, wndUnitGrid)

  if (not wndUnitGrid) then
    return nil
  end

  Print("wndUnitGrid:GetName(): " .. wndUnitGrid:GetName() .. "; strUnitName: " .. tostring(strUnitName))

  local tRowIndex

  for i = 1, wndUnitGrid:GetRowCount() do
    local strCurrUnitName = wndUnitGrid:GetCellText(i, 1)
    if (strUnitName == strCurrUnitName) then
      tRowIndex = i
      return tRowIndex
    end
  end

  return nil
end

function Nameplacer:GetUnitNameplatePositionSetting(strUnitName)
  return self.tUnits[strUnitName]
end

function Nameplacer:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {-- "UnitOrPackageName",
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-------------------------------------------------------------------------
-- Initialize the addon properties after the selection of a unit
-- Update the UI elements as well
-------------------------------------------------------------------------
function Nameplacer:InitUnitSelection(strUnitName, bUpdateGridSelection)

  Print("Nameplacer:InitUnitSelection; strUnitName: " .. tostring(strUnitName))

  local tPosSettings = self.tUnits[strUnitName]
  local wndSelectedGrid

  self.strSelectedUnitName = strUnitName

  if (tPosSettings) then
    if (tPosSettings.nVerticalOffset) then
      wndSelectedGrid = self.wndUnitGridCustom

      -- Set the spinner box value
      self.wndInputBoxVerticalOffset:SetValue(tPosSettings.nVerticalOffset)
    elseif (tPosSettings.nAnchorId == CombatFloater.CodeEnumFloaterLocation.Chest) then
      wndSelectedGrid = self.wndUnitGridChest
    else
      wndSelectedGrid = self.wndUnitGridBottom
    end

  --[[else
    self.strSelectedUnitName = nil
    ]]

  end

  -- When a unit is selected we disable the list buttons
  for _, wndUnitPosListContainer in pairs(self.tUnitLists) do

    local wndButtonSelectUnitPosList = wndUnitPosListContainer:FindChild("ButtonSelectUnitPosList")
    wndButtonSelectUnitPosList:Enable(not tPosSettings)
  end

  if (wndSelectedGrid and bUpdateGridSelection) then
    local nUnitRowIndex = self:GetUnitRowIndex(strUnitName, wndSelectedGrid)
    self:SelectUnitGridRow(nUnitRowIndex, wndSelectedGrid)
  end

  if (bUpdateGridSelection) then
    self:ResetGridSelection(wndSelectedGrid)
  end
end


-------------------------------------------------------------------------
-- On add unit button press
-------------------------------------------------------------------------
function Nameplacer:OnAddUnit()
  local wndUnitNameInput = self.wndUnitNameInput
  local wndInputBoxVerticalOffset = self.wndInputBoxVerticalOffset
  local strUnitName = trim(wndUnitNameInput:GetText())
  local nVerticalOffset = wndInputBoxVerticalOffset:GetValue()

  Print("strUnitName: " .. strUnitName .. "; nVerticalOffset: " .. tostring(nVerticalOffset))

  if (not self.wndSelectedUnitPosList) then
    self.wndSelectedUnitPosList = self.wndUnitListChest
  end

  Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())

  if (not self.tUnits[strUnitName]) then
    local nNewRowIndex = self:AddUnit(strUnitName, self:FromListToGrid(self.wndSelectedUnitPosList), nVerticalOffset)
  end
end

function Nameplacer:OnButtonSignalButtonSelectUnitPosList(wndHandler, wndControl, eMouseButton)

  Print("OnButtonSignalButtonSelectUnitPosList; wndControl: " .. wndControl:GetName())

  local wndSelectedUnitPosListContainer = wndHandler:GetParent()
  self:ResetListSelection(wndSelectedUnitPosListContainer)
end

function Nameplacer:OnButtonSignalChangeUnitList(wndHandler, wndControl, eMouseButton)

  local strButtonName = wndControl:GetName()
  Print("OnButtSigChangePos; wndControl: " .. wndControl:GetName())

  if (strButtonName == STR_BTN_FROM_CHEST_TO_BOTTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridChest)
    self:AddUnit(self.strSelectedUnitName, self.wndUnitGridBottom)
    -- self.wndUnitGridBottom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridBottom))
  elseif (strButtonName == STR_BTN_FROM_BOTTOM_TO_CHEST) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:AddUnit(self.strSelectedUnitName, self.wndUnitGridChest)
    -- self.wndUnitGridChest:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridChest))
  elseif (strButtonName == STR_BTN_FROM_BOTTOM_TO_CUSTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:AddUnit(self.strSelectedUnitName, self.wndUnitGridCustom, N_DEFAULT_VERTICAL_OFFSET)
    -- self.wndUnitGridCustom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridCustom))
  elseif (strButtonName == STR_BTN_FROM_CUSTOM_TO_BOTTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridCustom)
    self:AddUnit(self.strSelectedUnitName, self.wndUnitGridBottom)
    -- self.wndUnitGridBottom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridBottom))
  end
end


function Nameplacer:OnButtonSignalDeleteUnit()
  local wndUnitNameInput = self.wndUnitNameInput
  local strUnitName = trim(wndUnitNameInput:GetText())

  Print("strUnitName: " .. strUnitName)
  Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())

  self:DeleteUnit(strUnitName, self:FromListToGrid(self.wndSelectedUnitPosList))

  self:FireEventUnitNameplatePositionChanged(strUnitName, {nAnchorId = CombatFloater.CodeEnumFloaterLocation.Top, nVerticalOffset = 0})
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

    -- unit lists containers
    self.wndUnitListChest = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CHEST)
    self.wndUnitListBottom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_BOTTOM)
    self.wndUnitListCustom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CUSTOM)

    -- unit grids
    self.wndUnitGridChest = self.wndUnitListChest:FindChild(STR_UNIT_GRID_NAME)
    self.wndUnitGridBottom = self.wndUnitListBottom:FindChild(STR_UNIT_GRID_NAME)
    self.wndUnitGridCustom = self.wndUnitListCustom:FindChild(STR_UNIT_GRID_NAME)
    self.wndSelectedUnitPosList = self.wndUnitListChest

    -- buttons
    self.wndButtonFromChestToBottom = self.wndMain:FindChild(STR_BTN_FROM_CHEST_TO_BOTTOM)
    self.wndButtonFromBottomToChest = self.wndMain:FindChild(STR_BTN_FROM_BOTTOM_TO_CHEST)
    self.wndButtonFromBottomToCustom = self.wndMain:FindChild(STR_BTN_FROM_BOTTOM_TO_CUSTOM)
    self.wndButtonFromCustomToBottom = self.wndMain:FindChild(STR_BTN_FROM_CUSTOM_TO_BOTTOM)

    -- input boxes
    self.wndUnitNameInput = self.wndMain:FindChild(STR_UNIT_NAME_INPUT)
    self.wndInputBoxVerticalOffset = self.wndMain:FindChild(STR_VERTICAL_OFFSET_INPUT)
    self.wndContainerVerticalOffset = self.wndMain:FindChild(STR_VERTICAL_OFFSET_CONTAINER)

    self.wndInputBoxVerticalOffset:SetMinMax(-500, 500)
    self.wndInputBoxVerticalOffset:SetValue(N_DEFAULT_VERTICAL_OFFSET)


    self.tUnitLists = { [STR_UNIT_LIST_NAME_CHEST] = self.wndUnitListChest, [STR_UNIT_LIST_NAME_BOTTOM] = self.wndUnitListBottom, [STR_UNIT_LIST_NAME_CUSTOM] = self.wndUnitListCustom }
    self.tUnitGrids = { [STR_UNIT_GRID_NAME_CHEST] = self.wndUnitGridChest, [STR_UNIT_GRID_NAME_BOTTOM] = self.wndUnitGridBottom, [STR_UNIT_GRID_NAME_CUSTOM] = self.wndUnitGridCustom }

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

function Nameplacer:OnEditBoxChangedUnitNameInput(wndHandler, wndControl, strText)

  self:InitUnitSelection(strText, true)
end

-----------------------------------------------------------------------------------------------
-- Nameplacer OnLoad
-----------------------------------------------------------------------------------------------
function Nameplacer:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("Nameplacer.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

---------------------------------------------------------------------------------------------------
-- NameplacerForm Functions
---------------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Nameplacer:OnOK()
  self.wndMain:Close() -- hide the window
end

---------------------------------------------------------------------------------------------------
-- When the Close button is clicked
---------------------------------------------------------------------------------------------------
function Nameplacer:OnButtonSignalButtonClose()
  self.wndMain:Close() -- hide the window
end

-------------------------------------------------------------------------
-- On unit list row selection change
-------------------------------------------------------------------------
function Nameplacer:OnGridSelChangeUnit(wndControl, wndHandler, iRow, iCol)

  Print("wndHandler: " .. wndHandler:GetName() .. "; wndControl: " .. wndControl:GetName() .. "; iRow: " .. tostring(iRow) .. "; iCol: " .. tostring(iCol))
  local strUnitName = wndHandler:GetCellText(iRow, 1)
  local nVerticalOffset = wndHandler:GetCellText(iRow, 2)

  self:UpdateUnitNameInput(strUnitName, true)

  if (not self.tUnitGrids) then
    Print("not self.tUnitGrids")
  end
  -- Print(table.tostring(self.tUnitGrids))
  -- wndControl:SetCurrentRow(iRow)

  -- self:ResetGridSelection(wndHandler)
end

---------------------------------------------------------------------------------------------------
-- on SlashCommand "/nameplacer"
---------------------------------------------------------------------------------------------------
function Nameplacer:OnNameplacerOn()
  self.wndMain:Invoke() -- show the window

  -- populate the units lists
  self:PopulateUnitGrids()

  self:ResetListSelection()
  self:ResetGridSelection()

  local tPlayer = GameLib.GetPlayerUnit()
  if (tPlayer) then
    local tCurrentTarget = tPlayer:GetTarget()
    if (tCurrentTarget) then
      local strCurrentTargetName = tCurrentTarget:GetName()

      self:UpdateUnitNameInput(strCurrentTargetName, true)
end
  end
end

function Nameplacer:OnTargetUnitChanged(tTarget)

  if (not tTarget or not self.wndMain:IsVisible()) then return end

  local strUnitName = tTarget:GetName()
  self:UpdateUnitNameInput(strUnitName, true)
end

---------------------------------------------------------------------------------------------------
-- NameplacerConfigForm Functions
---------------------------------------------------------------------------------------------------

--function Nameplacer:OnUnitPosListGainedFocus(wndHandler, wndControl)
--
--  self.wndSelectedUnitPosList = wndHandler
--
--  local wndUnitPosListContainerBackground
--
--  for strUnitPosListName, wndUnitPosList in pairs(self.tUnitLists) do
--    local wndCurrUnitPosList = wndControl:FindChild(strUnitPosListName)
--
--    if wndCurrUnitPosList then
--
--      self.wndSelectedUnitPosList = wndCurrUnitPosList
--      wndUnitPosListContainerBackground = wndControl:FindChild("Background")
--      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_SELECTED_BG)
--    else
--
--      local wndUnitPosListContainer = wndUnitPosList:GetParent()
--      wndUnitPosListContainerBackground = wndUnitPosListContainer:FindChild("Background")
--      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_UNSELECTED_BG)
--    end
--  end
--end


function Nameplacer:OnRestore(saveLevel, savedData)

  Print(table.tostring(savedData.tUnits))

  if (savedData.tUnits) then
    self.tUnits = savedData.tUnits
  end
end

function Nameplacer:OnSave(saveLevel)
  if saveLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
    return nil
  end

  local savedData = {}

  savedData.tUnits = self.tUnits

  return savedData
end

function Nameplacer:OnSpinnerChanged(wndHandler, wndControl)

  -- Print("Nameplacer:OnSpinnerChanged; wndHandler:GetName(): " .. wndHandler:GetName() .. "; wndControl:GetName(): " .. wndControl:GetName())
  local nVerticalOffset = wndHandler:GetValue()

  -- If we're changing the vertical offset of an already stored unit we retrive its value from the table
  -- otherwise we create a new one with a fake initial vertical offset
  local tUnitPosSettings = self.tUnits[self.strSelectedUnitName]

  -- Print("Nameplacer:OnSpinnerChanged; tUnitPosSettings: " .. table.tostring(tUnitPosSettings) .. "; nVerticalOffset: " .. tostring(nVerticalOffset))

  -- If the vertical offset has been changed
  if (not tUnitPosSettings or nVerticalOffset ~= tUnitPosSettings.nVerticalOffset) then
    if (not tUnitPosSettings) then
      tUnitPosSettings = { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Bottom, nVerticalOffset = nVerticalOffset }
    else
    tUnitPosSettings.nVerticalOffset = nVerticalOffset
    end

    local nRowIndex = self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridCustom)
    self:UpdateVerticalOffsetCell(nRowIndex, nVerticalOffset)

    Print("Nameplacer:OnSpinnerChanged; self.strSelectedUnitName: " .. tostring(self.strSelectedUnitName) .. "; tUnitPosSettings: " .. table.tostring(tUnitPosSettings))

    self:FireEventUnitNameplatePositionChanged(self.strSelectedUnitName, tUnitPosSettings)
  end
end


function Nameplacer:OnWindowGainedFocusGrid( wndHandler, wndControl )

    Print("Nameplacer:OnWindowGainedFocusGrid; wndHandler: " .. wndHandler:GetName() .. "; wndControl: " .. wndControl:GetName())
end

---------------------------------------------------------------------------------------------------
-- Populate the unit grids
---------------------------------------------------------------------------------------------------
function Nameplacer:PopulateUnitGrids()

  Print(table.tostring(self.tUnits))

  if (self.tUnits and (not self.wndUnitGridChest or self.wndUnitGridChest:GetRowCount() <= 0)
      and (not self.wndUnitGridBottom or self.wndUnitGridBottom:GetRowCount() <= 0)
      and (not self.wndUnitGridCustom or self.wndUnitGridCustom:GetRowCount() <= 0)) then

    for strUnitName, tUnitInfo in pairs(self.tUnits) do

      if (tUnitInfo.nAnchorId and tUnitInfo.nVerticalOffset) then
        self:AddUnit(strUnitName, self.wndUnitGridCustom, tUnitInfo.nVerticalOffset, true)
      elseif (tUnitInfo.nAnchorId and tUnitInfo.nAnchorId == CombatFloater.CodeEnumFloaterLocation.Chest) then
        self:AddUnit(strUnitName, self.wndUnitGridChest, nil, true)
      else
        self:AddUnit(strUnitName, self.wndUnitGridBottom, nil, true)
      end
    end
  end
end


-------------------------------------------------------------------------
-- Update the selected unit and signal the update
-------------------------------------------------------------------------
function Nameplacer:FireEventUnitNameplatePositionChanged(strUnitName, tNameplatePosition)
  -- self.strSelectedUnitName = strUnitName
  Print("Nameplacer:FireEventUnitNameplatePositionChanged; firing Nameplacer_UnitNameplatePositionChanged event; strUnitName: " .. tostring(strUnitName))

  if (not tNameplatePosition) then
    return
  end

  Print("Nameplacer:FireEventUnitNameplatePositionChanged; firing Nameplacer_UnitNameplatePositionChanged event; strUnitName: " .. tostring(strUnitName) .. "; tNameplatePosition: " .. table.tostring(tNameplatePosition))
  Event_FireGenericEvent("Nameplacer_UnitNameplatePositionChanged", strUnitName, tNameplatePosition)
end


-------------------------------------------------------------------------
-- Unselect any grid selection other than the selected one
-------------------------------------------------------------------------
function Nameplacer:ResetGridSelection(wndSelectedGrid)

  for _, wndGrid in pairs(self.tUnitGrids) do

    if (wndSelectedGrid ~= wndGrid) then
      -- Print("ResetGridSelection: " .. wndGrid:GetParent():GetName())
      wndGrid:SetCurrentRow(0)
    end
  end

  -- We always want to have a grid container selected because it's going to be as grid selection
  -- for the next unit addition.
  -- We only change the grid container selection if we're actually selecting a grid row
  -- if (wndSelectedGrid) then
    self:ResetListSelection(wndSelectedGrid and wndSelectedGrid:GetParent() or nil)
  -- end
end


function Nameplacer:ResetListSelection(wndSelectedUnitPosListContainer)

  -- Print("Nameplacer:ResetListSelection; wndSelectedUnitPosListContainer: " .. tostring(wndSelectedUnitPosListContainer))

  -- if (self.wndSelectedUnitPosList == wndSelectedUnitPosListContainer) then
  --   return
  -- end

  -- First initialization
  if (not wndSelectedUnitPosListContainer and self.wndSelectedUnitPosList) then
    -- Print("Nameplacer:ResetListSelection; initializing wndSelectedUnitPosListContainer; " .. tostring(self.wndSelectedUnitPosList))

    wndSelectedUnitPosListContainer = self.wndSelectedUnitPosList
  else
    self.wndSelectedUnitPosList = wndSelectedUnitPosListContainer
  end

  -- Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())
  local strSelectedUnitPosContainerName
  local wndUnitPosListContainerBackground

  if (wndSelectedUnitPosListContainer) then
    strSelectedUnitPosContainerName = wndSelectedUnitPosListContainer:GetName()
    wndUnitPosListContainerBackground = wndSelectedUnitPosListContainer:FindChild("Background")
    wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_SELECTED_BG)
  end

  for _, wndUnitPosListContainer in pairs(self.tUnitLists) do

    if (not wndSelectedUnitPosListContainer or wndUnitPosListContainer ~= wndSelectedUnitPosListContainer) then

      wndUnitPosListContainerBackground = wndUnitPosListContainer:FindChild("Background")
      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_UNSELECTED_BG)
    end
  end

  -- local bIsRowSelected = self.strSelectedUnitName ~= nil and self.strSelectedUnitName ~= ''
  local bIsRowSelected = self.tUnits[self.strSelectedUnitName] ~= nil

  -- Print("self.strSelectedUnitName: " .. tostring(self.strSelectedUnitName))

  --[[
  if (wndGrid == self.wndUnitGridCustom) then
    -- Enabling/disabling vertical offset input box
    local bVerticalOffsetInputBoxEnabled = wndUnitGrid == self.wndUnitGridCustom and true or false
    self.wndInputBoxVerticalOffset:Enable(bVerticalOffsetInputBoxEnabled)
    self.wndInputBoxVerticalOffset:Show(bVerticalOffsetInputBoxEnabled)
  end
  ]]

  if (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_CHEST) then
    self.wndButtonFromChestToBottom:Enable(bIsRowSelected)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(false)
    self.wndInputBoxVerticalOffset:Enable(false)
    self.wndContainerVerticalOffset:Show(false)
  elseif (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_BOTTOM) then
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(bIsRowSelected)
    self.wndButtonFromBottomToCustom:Enable(bIsRowSelected)
    self.wndButtonFromCustomToBottom:Enable(false)
    self.wndInputBoxVerticalOffset:Enable(false)
    self.wndContainerVerticalOffset:Show(false)
  elseif (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_CUSTOM) then
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(bIsRowSelected)
    self.wndInputBoxVerticalOffset:Enable(bIsRowSelected)
    self.wndContainerVerticalOffset:Show(true)
  else
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(false)
    self.wndInputBoxVerticalOffset:Enable(false)
    self.wndContainerVerticalOffset:Show(false)
  end
end

-----------------------------------------------------------------------------------------------
-- Select the specified grid row ensuring that it's visible and the vertical offset input box
-- is enabled/disabled accordingly
-----------------------------------------------------------------------------------------------
function Nameplacer:SelectUnitGridRow(nRowIndex, wndGrid)

  -- Print("nRowIndex: " .. tostring(nRowIndex))
  -- Print("wndGrid: " .. wndGrid:GetParent():GetName())
  wndGrid:SelectCell(nRowIndex, 1)
  wndGrid:EnsureCellVisible(nRowIndex, 1)

  -- if (wndGrid == self.wndUnitGridCustom) then
    -- Enabling/disabling vertical offset input box
    -- local bVerticalOffsetInputBoxEnabled = (wndGrid == self.wndUnitGridCustom) and true or false
    -- self.wndInputBoxVerticalOffset:Enable(bVerticalOffsetInputBoxEnabled)
    -- self.wndInputBoxVerticalOffset:Show(bVerticalOffsetInputBoxEnabled)
  -- end
end

---------------------------------------------------------------------------------------------------
-- Update the selected unit input box
---------------------------------------------------------------------------------------------------
function Nameplacer:UpdateUnitNameInput(strUnitName, bUpdateList)

  self.wndUnitNameInput:SetText(strUnitName)

  if (strUnitName ~= "") then
  self:InitUnitSelection(strUnitName, bUpdateList)
end
end

function Nameplacer:UpdateVerticalOffsetCell(nRowIndex, nVerticalOffset)
  if (not nRowIndex) then return end

  self.wndUnitGridCustom:SetCellText(nRowIndex, 2, tostring(nVerticalOffset))
end


-----------------------------------------------------------------------------------------------
-- Nameplacer Instance
-----------------------------------------------------------------------------------------------
local NameplacerInst = Nameplacer:new()
NameplacerInst:Init()


function table.val_to_str(v)
  if "string" == type(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v, '"', '\\"') .. '"'
  else
    return "table" == type(v) and table.tostring(v) or
        tostring(v)
  end
end

function table.key_to_str(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. table.val_to_str(k) .. "]"
  end
end

function table.tostring(tbl)

  if (not tbl) then
    return "nil"
  end

  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, table.val_to_str(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result,
        table.key_to_str(k) .. "=" .. table.val_to_str(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end
