local __namespace, __module = ...

local Array = __module.Array --- @class Array
local Addon = __module.Addon --- @class Addon
local CrossExp = __module.CrossExp --- @class Addon
local Settings = __module.Settings

local onInit = Addon.onInit
local onLoad = Addon.onLoad
local useState = Addon.useState
local useEffect = Addon.useEffect
local useEvent = Addon.useEvent
local useSlashCmd = Addon.useSlashCmd
local useHook = Addon.useHook
local print = Addon.print
local useGossipUpdateHook = CrossExp.useGossipUpdateHook

local module = {}

local isPlaying = useState(false)
local textHistory = Array.new()
local alertVersion = 1

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
    CrossExp.initSettings()

    if (alertVersion > Settings.alert.get()) then
      print(
        "Hello! I have a brand new settings panel, check it out from the interface menu or by right cliking the play/stop button :D"
      )

      Settings.alert.set(alertVersion)
    end
  end
)

useEvent(
  function()
    isPlaying.set(false)
  end, { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" }
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

useGossipUpdateHook(
  function(self, frame)
    if not frame:IsShown() then
      return
    end

    module.ttsAutoPlay("gossip")
  end
)
useHook(
  "OnHide", function()
    module.ttsAutoStop()
  end, "secure-widget", GossipFrame
)

useHook(
  "OnEvent", function(self, frame, event)
    if not frame:IsShown() then
      return
    end

    if event == "QUEST_GREETING" then
      module.ttsAutoPlay("quest:greeting")
    elseif event == "QUEST_DETAIL" then
      module.ttsAutoPlay("quest:detail")
    elseif event == "QUEST_PROGRESS" then
      module.ttsAutoPlay("quest:progress")
    elseif event == "QUEST_COMPLETE" then
      module.ttsAutoPlay("quest:reward")
    end
  end, "secure-widget", QuestFrame
)
useHook(
  "OnHide", function()
    module.ttsAutoStop()
  end, "secure-widget", QuestFrame
)

function module.ttsAutoPlay(source)
  if source:find("quest") and not Settings.autoReadQuest.get() then
    return
  elseif source:find("gossip") and not Settings.autoReadGossip.get() then
    return
  end

  if isPlaying.get() then
    module.ttsAutoStop()
  end

  local text = module.getText(source)

  local isRecentText = textHistory:some(
    function(element, index, array)
      return element == text
    end
  )

  textHistory:unshift(text)
  textHistory = textHistory:slice(1, 10)

  if isRecentText and Settings.skipRecentText.get() then
    return
  end

  C_Timer.After(
    0.1, function()
      module.ttsPlay(text)
    end
  )
end

function module.ttsAutoStop()
  if not Settings.autoStopRead.get() then
    return
  end

  module.ttsStop()
end

function module.ttsToggle(source)
  if isPlaying.get() then
    module.ttsStop()
  else
    module.ttsPlay(module.getText(source))
  end
end

function module.ttsPlay(text)
  isPlaying.set(true)

  C_VoiceChat.SpeakText(
    module.getVoice().voiceID, text, Enum.VoiceTtsDestination.LocalPlayback,
    Settings.voiceSpeed.get(), Settings.voiceVolume.get()
  )
end

function module.ttsStop()
  C_VoiceChat.StopSpeakingText()
end

function module.getText(source)
  local toRet = ""

  source = module.guessSource(source)

  if source == "gossip" then
    local npcName = UnitName("npc")
    local gossip = CrossExp.getGossipText()

    if Settings.readNpcName.get() then
      toRet = toRet .. "\n" .. npcName .. ":"
    end

    toRet = toRet .. "\n" .. gossip .. "."
  elseif source == "quest:focused" then
    local title = CrossExp.getQuestLogTitle()
    local description, objective = GetQuestLogQuestText()

    if Settings.readTitle.get() then
      toRet = toRet .. "\n" .. title .. "."
    end

    toRet = toRet .. "\n" .. description .. "."

    if Settings.readObjective.get() then
      toRet = toRet .. "\n" .. objective .. "."
    end
  elseif source == "quest:greeting" then
    local npcName = UnitName("npc")
    -- local title = GetTitleText()
    local greeting = GetGreetingText()

    if Settings.readNpcName.get() then
      toRet = toRet .. "\n" .. npcName .. ":"
    end

    toRet = toRet .. "\n" .. greeting .. "."
  elseif source == "quest:detail" then
    local title = GetTitleText()
    local description = GetQuestText()
    local objective = GetObjectiveText()

    if Settings.readTitle.get() then
      toRet = toRet .. "\n" .. title .. "."
    end

    toRet = toRet .. "\n" .. description .. "."

    if Settings.readObjective.get() then
      toRet = toRet .. "\n" .. objective .. "."
    end
  elseif source == "quest:progress" then
    -- local title = GetTitleText()
    local progress = GetProgressText()

    toRet = toRet .. "\n" .. progress .. "."
  elseif source == "quest:reward" then
    -- title = GetTitleText()
    local reward = GetRewardText()

    toRet = toRet .. "\n" .. reward .. "."
  elseif source == "book:1" then
    local title = ItemTextGetItem()
    local description = ItemTextGetText()

    if Settings.readTitle.get() then
      toRet = toRet .. "\n" .. title .. "."
    end

    toRet = toRet .. "\n" .. description .. "."
  elseif source and source:find("^book:") then
    local description = ItemTextGetText()

    toRet = toRet .. "\n" .. description .. "."
  end

  toRet = toRet:gsub("<", ""):gsub(">", "")

  return toRet
end

function module.guessSource(source)
  local toRet = source

  if source == nil and CrossExp.isQuestFrameShown() then
    toRet = "quest"
  elseif source == nil and GossipFrame:IsShown() then
    toRet = "gossip"
  elseif source == nil and ItemTextFrame:IsShown() then
    toRet = "book"
  end

  source = toRet

  if source == "quest" and QuestFrameGreetingPanel:IsShown() then
    toRet = "quest:greeting"
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

function module.getVoice()
  local toRet = Settings.voice1.get()
  local unitSex = UnitSex("questnpc") or UnitSex("npc")

  if unitSex == 2 then -- male
    toRet = Settings.voice1.get()
  elseif unitSex == 3 then -- female
    toRet = Settings.voice2.get()
  else
    toRet = Settings.voice3.get()
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

function module.openSettings()
  InterfaceOptionsFrame_OpenToCategory(__namespace)
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
    toRet:SetFrameStrata("HIGH")
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

  CrossExp.initPlayButton(buttons, factory)

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

function module.getState()
  return { isPlaying = isPlaying }
end

__module.Main = module
