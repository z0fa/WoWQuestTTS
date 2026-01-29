local __namespace, __module = ...
local Reactivity = __module.Addon --- @class Reactivity
local Addon = __module.Addon --- @class Addon
local watch = Reactivity.watch
local onLoad = Addon.onLoad
local useHook = Addon.useHook

onLoad(
  function()
    local isPlaying = __module.Main.getState().isPlaying

    local source = "gossip"

    local frame = ((ImmersionFrame or {}).TalkBox or {}).MainFrame

    if not frame then
      return
    end

    local button = CreateFrame("Button", nil, frame)

    button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    button:SetHighlightTexture(
      "Interface\\Buttons\\UI-Common-MouseHilight", "ADD"
    )
    button:SetPoint("TOPRIGHT", -59, -17)
    button:SetWidth(22)
    button:SetHeight(22)
    button:SetFrameStrata("HIGH")
    button:RegisterForClicks("LeftButtonUp", "RightButtonDown")
    button:SetScript(
      "OnClick", function(_, event)
        if event == "RightButton" then
          Main.openSettings()
        else
          Main.ttsToggle(source)
        end
      end
    )

    watch(
      { isPlaying }, function(newValue, oldValue)
        if newValue then
          button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
        else
          button:SetNormalTexture(
            "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
          )
        end
      end
    )

    useHook(

      function(self, frame, title, text, npcType, explicitUnit, isToastPlayback)
        if npcType:find("GossipGossip") then
          source = "gossip"
        elseif npcType:find("AvailableQuest") and GetGreetingText() ~= "" then
          source = "quest:greeting"
        elseif npcType:find("IncompleteQuest") then
          source = "quest:progress"
        elseif npcType:find("ActiveQuest") and GetProgressText() ~= "" then
          source = "quest:progress"
        elseif npcType:find("ActiveQuest") then
          source = "quest:reward"
        elseif npcType:find("AvailableQuest") then
          source = "quest:detail"
        end

        if not npcType:find("GossipGossip") then
          Main.ttsAutoPlay(source)
        end
      end, "UpdateTalkingHead", "secure-function", ImmersionFrame
    )

    useHook(
      function()
        Main.ttsAutoStop()
      end, "OnHide", "secure-widget", ImmersionFrame
    )
  end
)
