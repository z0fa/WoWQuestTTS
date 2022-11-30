local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon

local onLoad = Addon.onLoad
local useHook = Addon.useHook
local useEffect = Addon.useEffect

local module = {}

function module.init()
  local Main = __module.Main
  local isPlaying = Main.getState().isPlaying

  local source = "gossip"

  local frame = ((ImmersionFrame or {}).TalkBox or {}).MainFrame

  if not frame then
    return
  end

  local button = CreateFrame("Button", nil, frame)

  button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
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

  useEffect(
    function()
      if isPlaying.get() then
        button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
      else
        button:SetNormalTexture(
          "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
        )
      end
    end, { isPlaying }
  )

  useHook(
    "UpdateTalkingHead",
    function(self, frame, title, text, npcType, explicitUnit, isToastPlayback)
      if npcType:find("GossipGossip") then
        source = "gossip"
      elseif npcType:find("IncompleteQuest") then
        source = "quest:progress"
      elseif npcType:find("ActiveQuest") then
        source = "quest:reward"
      elseif npcType:find("AvailableQuest") then
        source = "quest:detail"
      end

      if not npcType:find("GossipGossip") then
        Main.ttsAutoPlay(source)
      end

      return self.__oldFn(
        frame, title, text, npcType, explicitUnit, isToastPlayback
      )
    end, "function", ImmersionFrame
  )

  useHook(
    "OnHide", function()
      Main.ttsStop()
    end, "secure-widget", ImmersionFrame
  )
end

onLoad(
  function()
    module.init()
  end
)

__module.Immersion = module
