local __namespace, __module = ...

local Array = __module.Array --- @class Array
local Addon = __module.Addon --- @class Addon

local onInit = Addon.onInit
local onLoad = Addon.onLoad
local useState = Addon.useState
local useEffect = Addon.useEffect
local useEvent = Addon.useEvent
local useSlashCmd = Addon.useSlashCmd
-- local useDebugValue = Addon.useDebugValue
local useSavedVariable = Addon.useSavedVariable
local print = Addon.print
local nextTick = Addon.nextTick

local module = {}

local isPlaying = useState(false)

local alertVersion = 1
local settings = __module.settings

onInit(
  function()
    QuestTTSAddon = {}
    QuestTTSAddon.name = __namespace

    QuestTTSAddon.keybindReadQuest = function(...)
      module.ttsToggle()
    end
  end
)

onLoad(
  function()
    module.initPlayButton(module.ttsToggle, module.openSettings)

    if (alertVersion > settings.alert.get()) then
      print(
        "Hello! I have a brand new settings panel, check it out from the interface menu or by right cliking the play/stop button :D"
      )
      settings.alert.set(alertVersion)
    end
  end
)

useEvent(
  function()
    isPlaying.set(false)
  end, { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" }
)
useEvent(
  function()
    module.ttsStop()
  end, { "ITEM_TEXT_CLOSED" }
)
useEvent(
  function()
    module.ttsStop()
  end, { "GOSSIP_CLOSED" }
)
useEvent(
  function()
    module.ttsStop()
  end, { "QUEST_FINISHED" }
)

useEvent(
  function()
    module.ttsAutoPlay("gossip")
  end, { "GOSSIP_SHOW" }
)
useEvent(
  function()
    module.ttsAutoPlay("quest:detail")
  end, { "QUEST_DETAIL" }
)
useEvent(
  function()
    module.ttsAutoPlay("quest:progress")
  end, { "QUEST_PROGRESS" }
)
useEvent(
  function()
    module.ttsAutoPlay("quest:complete")
  end, { "QUEST_COMPLETE" }
)

useSlashCmd(
  function(cmd)
    if cmd == "play" then
      module.ttsToggle()
      print("Playing...")
    elseif cmd == "stop" then
      module.ttsStop()
      print("Stopping...")
    elseif cmd == "settings" then
      module.openSettings()
    end
  end, { "qtts" }
)

function module.ttsAutoPlay(source)
  if source:find("quest") and not settings.autoReadQuest.get() then
    return
  elseif source:find("gossip") and not settings.autoReadGossip.get() then
    return
  end

  module.ttsPlay(source)
end

function module.ttsToggle(source)
  if isPlaying.get() then
    module.ttsStop()
  else
    module.ttsPlay(source)
  end
end

function module.ttsPlay(source)
  local title = ""
  local description = ""
  local objective = ""
  local info = ""
  local reward = ""
  local progress = ""

  source = module.guessSource(source)

  if source == "quest:focused" then
    title = module.getQuestLogTitle()
    description, objective = GetQuestLogQuestText()
  elseif source == "gossip" then
    info = module.getGossipText()
  elseif source == "book:1" then
    title = ItemTextGetItem()
    description = ItemTextGetText()
  elseif source and source:find("^book:") then
    description = ItemTextGetText()
  elseif source == "quest:reward" then
    -- title = GetTitleText()
    reward = GetRewardText()
  elseif source == "quest:progress" then
    -- title = GetTitleText()
    progress = GetProgressText()
  elseif source == "quest:detail" then
    title = GetTitleText()
    description = GetQuestText()
    objective = GetObjectiveText()
  end

  local text = ""

  if settings.readTitle.get() then
    text = text .. "\n" .. title
  end

  text = text .. "\n" .. description

  if settings.readObjective.get() then
    text = text .. "\n" .. objective
  end

  text = text .. "\n" .. info
  text = text .. "\n" .. reward
  text = text .. "\n" .. progress

  C_VoiceChat.SpeakText(
    module.getVoice().voiceID, module.cleanText(text),
    Enum.VoiceTtsDestination.LocalPlayback, settings.voiceSpeed.get(),
    settings.voiceVolume.get()
  )

  isPlaying.set(true)
end

function module.ttsStop()
  C_VoiceChat.StopSpeakingText()
end

function module.guessSource(source)
  local toRet = source

  local isQuestFrame = QuestFrame:IsShown() or QuestLogFrame:IsShown() or QuestLogDetailFrame:IsShown()

  if source == nil and isQuestFrame then
    toRet = "quest"
  elseif source == nil and GossipFrame:IsShown() then
    toRet = "gossip"
  elseif source == nil and ItemTextFrame:IsShown() then
    toRet = "book"
  end

  source = toRet

  if source == "immersion" and module.immersionIsGossip() then
    toRet = module.immersionGuessSource()
  elseif source == "quest" and QuestFrameProgressPanel:IsShown() then
    toRet = "quest:progress"
  elseif source == "quest" and QuestFrameRewardPanel:IsShown() then
    toRet = "quest:reward"
  elseif source == "quest" and QuestFrame:IsShown() then
    toRet = "quest:detail"
  elseif source == "quest" then
    toRet = "quest:focused"
  elseif source == "book" then
    toRet = "book:" .. ItemTextGetPage()
  end

  return toRet
end

function module.immersionGuessSource()
  local toRet = nil

  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  local isGossip = icon:find("GossipGossipIcon")
  local isQuestProgress = icon:find("IncompleteQuestIcon")
  local isQuestReward = icon:find("ActiveQuestIcon")
  local isQuestDetail = icon:find("AvailableQuestIcon")

  if isGossip then
    toRet = "gossip"
  elseif isQuestProgress then
    toRet = "quest:progress"
  elseif isQuestReward then
    toRet = "quest:reward"
  elseif isQuestDetail then
    toRet = "quest:detail"
  end

  return toRet
end

function module.getVoice()
  local toRet = settings.voice1.get()
  local unitSex = UnitSex("questnpc") or UnitSex("npc")

  if unitSex == 2 then -- male
    toRet = settings.voice1.get()
  elseif unitSex == 3 then -- female
    toRet = settings.voice2.get()
  else
    toRet = settings.voice3.get()
  end

  local voices = Array.new(C_VoiceChat.GetTtsVoices())
  local voiceToRet = voices:find(
    function(v)
      if v.voiceID == toRet then
        return true
      end
    end
  )

  return voiceToRet
end

function module.cleanText(text)
  local toRet = text

  toRet = toRet:gsub("<", ""):gsub(">", "")

  return toRet
end

function module.openSettings()
  InterfaceOptionsFrame_OpenToCategory(__namespace)
  InterfaceOptionsFrame_OpenToCategory(__namespace)
end

function module.getGossipText()
  local toRet = ""

  if Addon.isRetail then
    toRet = C_GossipInfo.GetText()
  elseif Addon.isWOTLK then
    toRet = GetGossipText()
  end

  return toRet
end

function module.getFocusedQuestId()
  local toRet = 0

  if Addon.isRetail then
    toRet = QuestMapFrame_GetFocusedQuestID()
  elseif Addon.isWOTLK then
    toRet = GetQuestLogSelection()
  end

  return toRet
end

function module.getQuestLogTitle()
  local toRet = ""

  if Addon.isRetail then
    toRet = C_QuestLog.GetTitleForQuestID(module.getFocusedQuestId())
  elseif Addon.isWOTLK then
    toRet = GetQuestLogTitle(module.getFocusedQuestId())
  end

  return toRet
end

function module.immersionGetFrame()
  return ((ImmersionFrame or {}).TalkBox or {}).MainFrame
end

function module.initPlayButton(onLeftClick, onRightClick)
  local function factory(parent, x, y, source)
    local toRet = CreateFrame("Button", nil, parent)

    toRet:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    toRet:SetHighlightTexture(
      "Interface\\Buttons\\UI-Common-MouseHilight", "ADD"
    )
    toRet:SetPoint("TOPRIGHT", x, y)
    toRet:SetWidth(22)
    toRet:SetHeight(22)
    toRet:RegisterForClicks("LeftButtonUp", "RightButtonDown")
    toRet:SetScript(
      "OnClick", function(_, event)
        if event == "RightButton" then
          onRightClick()
        else
          onLeftClick(source)
        end
      end
    )

    return toRet
  end

  local buttons = Array.new()

  if Addon.isRetail then
    buttons:push(factory(QuestMapFrame.DetailsFrame, 18, 30, "quest:focused"))
    buttons:push(factory(QuestFrame, -10, -30, "quest"))
    buttons:push(factory(GossipFrame, -10, -30, "gossip"))
    buttons:push(factory(ItemTextFrame, -23, 0, "book"))
  elseif Addon.isWOTLK then
    buttons:push(factory(QuestFrame, -54, -20, "quest"))
    buttons:push(factory(QuestLogFrame, -24, -13, "quest:focused"))
    buttons:push(factory(QuestLogDetailFrame, -24, -13, "quest:focused"))
    buttons:push(factory(GossipFrame, -54, -20, "gossip"))
    buttons:push(factory(ItemTextFrame, -55, -14, "book"))
  end

  local immersionFrame = module.immersionGetFrame()

  if immersionFrame then
    buttons:push(factory(immersionFrame, -59, -17, "immersion"))
  end

  useEffect(
    function()
      if isPlaying.get() then
        buttons:forEach(
          (function(button)
            button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
          end)
        )
      else
        buttons:forEach(
          (function(button)
            button:SetNormalTexture(
              "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
            )
          end)
        )
      end
    end, { isPlaying }
  )
end
