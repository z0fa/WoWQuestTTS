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
local playSource = useState("")

local globalDB = "QuestTTSGlobalDB"
local alertVersion = 1
local settings = {
  readTitle = useSavedVariable(globalDB, "readTitle", true),
  readObjective = useSavedVariable(globalDB, "readObjective", true),
  voice1 = useSavedVariable(globalDB, "voice1", Enum.TtsVoiceType.Standard),
  voice2 = useSavedVariable(globalDB, "voice2", Enum.TtsVoiceType.Standard),
  voice3 = useSavedVariable(globalDB, "voice3", Enum.TtsVoiceType.Standard),
  alert = useSavedVariable(globalDB, "alert", 0),
  autoReadQuest = useSavedVariable(globalDB, "autoReadQuest", false),
  autoReadGossip = useSavedVariable(globalDB, "autoReadGossip", false),
}

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWOTLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

onInit(
  function()

    QuestTTSAddon = {}
    QuestTTSAddon.name = __namespace
    QuestTTSAddon.registerCheckSetting = function(...)
      module.registerCheckSetting(...)
    end
    QuestTTSAddon.registerVoiceSetting = function(...)
      module.registerVoiceSetting(...)
    end
    QuestTTSAddon.keybindReadQuest = function(...)
      module.keybindReadQuest(...)
    end
  end
)

onLoad(
  function()
    module.initPlayButton(module.keybindReadQuest, module.openSettings)

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
    module.updatePlayState(playSource.get(), false)
  end, { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" }
)

useEvent(
  function()
    module.updatePlayState("quest:detail", settings.autoReadQuest.get())
  end, { "QUEST_DETAIL" }
)
useEvent(
  function()
    module.updatePlayState("quest:progress", settings.autoReadQuest.get())
  end, { "QUEST_PROGRESS" }
)
useEvent(
  function()
    module.updatePlayState("quest:reward", settings.autoReadQuest.get())
  end, { "QUEST_COMPLETE" }
)
useEvent(
  function()
    module.updatePlayState(playSource.get(), false)
  end, { "QUEST_FINISHED" }
)

useEvent(
  function()
    module.updatePlayState("gossip", settings.autoReadGossip.get())
  end, { "GOSSIP_SHOW" }
)
useEvent(
  function()
    module.updatePlayState(playSource.get(), false)
  end, { "GOSSIP_CLOSED" }
)

useEvent(
  function()
    module.updatePlayState("book", false)
  end, { "ITEM_TEXT_READY" }
)
useEvent(
  function()
    module.updatePlayState(playSource.get(), false)
  end, { "ITEM_TEXT_CLOSED" }
)

useEffect(
  function()
    if not isPlaying.get() then
      C_VoiceChat.StopSpeakingText()
      return
    end

    local source = playSource.get()

    local title = ""
    local description = ""
    local objective = ""
    local info = ""
    local reward = ""
    local progress = ""

    if source == "quest:focused" then
      title = module.getQuestLogTitle()
      description, objective = GetQuestLogQuestText()
    elseif source == "gossip" then
      info = module.getGossipText()
    elseif source == "book:1" then
      title = ItemTextGetItem()
      description = ItemTextGetText()
    elseif source:find("^book:") then
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
      Enum.VoiceTtsDestination.LocalPlayback, C_TTSSettings.GetSpeechRate(),
      C_TTSSettings.GetSpeechVolume()
    )
  end, { isPlaying }
)

useSlashCmd(
  function(cmd)
    if cmd == "play" then
      module.keybindReadQuest()
      print("Playing...")
    elseif cmd == "stop" then
      module.updatePlayState(playSource.get(), false)
      print("Stopping...")
    elseif cmd == "settings" then
      module.openSettings()
    end
  end, { "qtts" }
)

function module.updatePlayState(source, playing)
  if source == "book" then
    source = "book:" .. ItemTextGetPage()
  end

  playSource.set(source)
  isPlaying.set(playing)
end

function module.keybindReadQuest()
  module.updatePlayState(
    module.getFocusedQuestId() and "quest:focused" or playSource.get(),
    not isPlaying.get()
  )
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

function module.registerCheckSetting(key, frame)
  local setting = settings[key]

  useEffect(
    function()
      frame:SetChecked(setting.get())
    end, { setting }
  )

  frame:SetScript(
    "OnClick", function()
      if frame:GetChecked() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
      else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
      end

      setting.set(frame:GetChecked())
    end
  )
end

function module.registerVoiceSetting(key, frame)
  local setting = settings[key]
  local voices = Array.new(C_VoiceChat.GetTtsVoices())

  useEffect(
    function()
      local voice = voices:find(
        function(v)
          if v.voiceID == setting.get() then
            return true
          end
        end
      )

      UIDropDownMenu_SetText(frame, (voice or {}).name)
    end, { setting }
  )

  UIDropDownMenu_SetWidth(frame, 350)

  UIDropDownMenu_Initialize(
    frame, function(_, level)
      if (level or 1) ~= 1 then
        return
      end

      voices:map(
        function(voice, i)
          local info = UIDropDownMenu_CreateInfo()
          info.text = voice.name
          info.value = voice.voiceID
          info.menuList = i
          info.checked = setting.get() == info.value
          info.func = function()
            setting.set(info.value)
          end

          UIDropDownMenu_AddButton(info)
        end
      )
    end
  )
end

function module.getGossipText()
  local toRet = ""

  if isRetail then
    toRet = C_GossipInfo.GetText()
  elseif isWOTLK then
    toRet = GetGossipText()
  end

  return toRet
end

function module.getFocusedQuestId()
  local toRet = 0

  if isRetail then
    toRet = QuestMapFrame_GetFocusedQuestID()
  elseif isWOTLK then
    toRet = GetQuestLogSelection()
  end

  return toRet
end

function module.getQuestLogTitle()
  local toRet = ""

  if isRetail then
    toRet = C_QuestLog.GetTitleForQuestID(module.getFocusedQuestId())
  elseif isWOTLK then
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

  if isRetail then
    buttons:push(factory(QuestMapFrame.DetailsFrame, 18, 30, "quest:focused"))
    buttons:push(factory(QuestFrame, -10, -30))
    buttons:push(factory(GossipFrame, -10, -30))
    buttons:push(factory(ItemTextFrame, -23, 0))
  elseif isWOTLK then
    buttons:push(factory(QuestFrame, -54, -20))
    buttons:push(factory(QuestLogFrame, -24, -13, "quest:focused"))
    buttons:push(factory(QuestLogDetailFrame, -24, -13, "quest:focused"))
    buttons:push(factory(GossipFrame, -54, -20))
    buttons:push(factory(ItemTextFrame, -55, -14))
  end

  local immersionFrame = module.immersionGetFrame()

  if immersionFrame then
    buttons:push(factory(immersionFrame, -59, -17))
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
