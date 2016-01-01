What's Nameplacer?
Nameplacer is a very simple addon that allows the player to save some basic (namely vertical) settings about where a unit's nameplate should be positioned.

Why Nameplacer?
Almost every nameplate addon has some settings related to nameplates vertical positioning. Unfortunately even the most advanced ones have some generic settings which do not cover the huge variety of creatures and creature sizes found in WildStar. Nameplacer it's here to give the player the opportunity to save a specific setting for each and every single unit (not just creatures).

How does it work?
Nameplacer does nothing on its own. It simply permanently stores some information about a list of units. The player can choose to add/remove a unit to/from the list or change the current settings. It's up to your favorite  nameplate addon make use of these information and display the nameplate accordingly to your settings.

OK, but how do I (the player) use it?
There are 2 ways to create/edit a setting:

 

1) Type /nameplacer in the chat.

This will bring up the configuration interface. It's initialized with the name of the unit currently targeted but you can manually type the unit's name that you want to  configure.

There are 3 different columns "Chest", "Bottom", "Custom".

As per name says, if you put the unit under one of these 3 categories you're creating a settings entry for all the units with the same name and your nameplate addon can use that information to properly place the nameplates according to your preferences.

 

2) Use one of the following macros:

 

Custom settings with default value (50 pixels)
/eval Apollo.GetAddon("Nameplacer"):AddTargetedUnitCustom()
Chest placement (beware, some units may have a weird chest anchor point)

/eval Apollo.GetAddon("Nameplacer"):AddTargetedUnitChest()
Bottom placement (beware, some units, especially the floating ones, may have a weird bottom anchor point)

/eval Apollo.GetAddon("Nameplacer"):AddTargetedUnitBottom()
OK, but how do I (the developer) use it?
 

Nameplacer is firing one specific event when a unit's setting are created/edited/removed:

 

Nameplacer_UnitNameplatePositionChanged
with 2 parameters:

 

- strUnitName : a string corresponding to the name of the unit of which the settings are created/changed
- tNameplatePositionSetting : a table containing the positioning settings
nAnchorId : a number corresponding to the nameplate anchor point
CombatFloater.CodeEnumFloaterLocation.Chest
CombatFloater.CodeEnumFloaterLocation.Bottom
CombatFloater.CodeEnumFloaterLocation.Top
nVerticalOffset : a number of pixels corresponding to the vertical offset . It's relative to the unit's bottom anchor point. 

In order to hook Nameplacer into your nameplate addon you'll probably want to do something like this:

self.nameplacer = Apollo.GetAddon("Nameplacer")

 

if (self.nameplacer) then
    Apollo.RegisterEventHandler("Nameplacer_UnitNameplatePositionChanged", "OnNameplatePositionSettingChanged", self)
end

In order to handle the new event you may want to have a function like this:

function NameplateAddon:OnNameplatePositionSettingChanged(strUnitName, tNameplatePositionSetting)
--  Do stuff
end
Nameplacer exposes a function called: 

 

function Nameplacer:GetUnitNameplatePositionSetting(strUnitName)


Accepting one parameter:


- strUnitName : a string representing the name of the unit

and returning the same table as before:

- tNameplatePositionSetting : a table containing the positioning settings
nAnchorId : a number corresponding to the nameplate anchor point
CombatFloater.CodeEnumFloaterLocation.Chest
CombatFloater.CodeEnumFloaterLocation.Bottom
CombatFloater.CodeEnumFloaterLocation.Top
nVerticalOffset : a number of pixels corresponding to the vertical offset . It's relative to the unit's bottom anchor point.
What about the performance?
Nameplacer is basically just an indexed table and LUA handles and accesses tables pretty nicely. As long as you don't have hundreds of records it really should have any noticeable impact on your performance.

I'm sold! What are the nameplates addons that support Nameplacer?
These are the addons that currently support Namaplacer:

 

TwinkiePlates
