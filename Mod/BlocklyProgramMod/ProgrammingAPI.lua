NPL.load("(gl)Mod/BlocklyProgramMod/ProgrammingCommand.lua")
NPL.load("(gl)Mod/BlocklyProgramMod/ProgrammingCommandQueue.lua")
NPL.load("(gl)Mod/BlocklyProgramMod/main.lua")
local Mod = commonlib.gettable("Mod.BlocklyProgramMod")
local CommandQueue = commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommandQueue")
local CommandFactory = commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Factory")
local API = commonlib.inherit(nil, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingAPI"))
local function assert(boolean, errorMessage)
    if not boolean then
        echo("devilwalk--------------------------------------assert:ProgrammingAPI.lua:" .. (errorMessage or ""))
    end
end
local function _onFrameMove(inst)
    --echo("devilwalk----------------------------debug:ProgrammingAPI.lua:_onFrameMove:inst.mCoroutine:"..tostring(inst.mCoroutine))
    if inst.mCoroutine then
        if "suspended" == coroutine.status(inst.mCoroutine) then
            coroutine.resume(inst.mCoroutine)
        elseif "dead" == coroutine.status(inst.mCoroutine) then
            inst.mCreator.mEventSystem:RemoveEventListener("FrameMove", _onFrameMove, inst)
        end
    end
end
function API:ctor()
    assert(self.mEntity ~= nil, "API:ctor:self.mEntity:nil")
    assert(self.mCreator ~= nil, "API:ctor:self.mCreator:nil")
    self.mCommandQueue = CommandQueue:new()
    self.mAlive = true
    self.mTimerTickCount = 0
    self.mCoroutine =
        coroutine.create(
        function()
            self.mTimer = commonlib.Timer:new()
            self.mTimer:Tick()
            self.mTimerInitTickCount = self.mTimer.lastTick
            self.mCommandQueue:execute()
            while self.mAlive do
                self.mCommandQueue:frameMove()
                self.mTimer:Tick()
                self.mTimerTickCount = self.mTimer.lastTick - self.mTimerInitTickCount
                coroutine.yield()
            end
        end
    )
    self.mCreator.mEventSystem:AddEventListener("FrameMove", _onFrameMove, self)
end
function API:setActive(activeFunction)
    self.active = activeFunction
end
function API:doNothing()
    coroutine.yield()
end
function API:move(count)
    self.mCommandQueue:add(CommandFactory.create("Move", {mEntity = self.mEntity, mDistance = count}))
    coroutine.yield()
end
function API:turn(type)
    if type == "left" then
        type = 0
    elseif type == "right" then
        type = 1
    elseif type == "back" then
        type = 2
    else
        assert(false, "API.turn:type:" .. tostring(type))
        type = 0
    end
    self.mCommandQueue:add(CommandFactory.create("Turn", {mEntity = self.mEntity, mType = type}))
    coroutine.yield()
end
function API:gotoPosition(x, y, z)
    self.mCommandQueue:add(CommandFactory.create("Goto", {mEntity = self.mEntity, mX = x, mY = y, mZ = z}))
    coroutine.yield()
end
function API:setPosition(x, y, z)
    self.mCommandQueue:add(CommandFactory.create("SetPosition", {mEntity = self.mEntity, mX = x, mY = y, mZ = z}))
    coroutine.yield()
end
function API:setEventFunction(name, parameters, func)
    if "OnKeyPressed" == name then
        if not self.mOnKeyPressed then
            self.mOnKeyPressed = {mKeys = {}}
            self.mOnKeyPressed.mFunction = function(inst, event)
                if event.event_type == "keyPressEvent" and inst.mOnKeyPressed.mKeys[event.keyname] then
                    local callback = inst.mOnKeyPressed.mKeys[event.keyname].mFunction
                    if callback then
                        if inst.mOnKeyPressed.mKeys[event.keyname].mAPI then
                            inst.mOnKeyPressed.mKeys[event.keyname].mAPI.mAlive = false
                            inst.mOnKeyPressed.mKeys[event.keyname].mAPI = nil
                        end
                        local new_api = API:new({mEntity = inst.mEntity, mCreator = inst.mCreator})
                        local coro =
                            coroutine.create(
                            function()
                                callback(new_api)
                            end
                        )
                        local function on_frame_move(key)
                            if key.mCoroutine then
                                if "suspended" == coroutine.status(key.mCoroutine) then
                                    coroutine.resume(key.mCoroutine)
                                elseif "dead" == coroutine.status(key.mCoroutine) then
                                    inst.mCreator.mEventSystem:RemoveEventListener("FrameMove", key.mOnFrameMove, key)
                                    key.mOnFrameMove = nil
                                end
                            end
                        end
                        inst.mOnKeyPressed.mKeys[event.keyname].mCoroutine = coro
                        inst.mOnKeyPressed.mKeys[event.keyname].mAPI = new_api
                        if not inst.mOnKeyPressed.mKeys[event.keyname].mOnFrameMove then
                            inst.mOnKeyPressed.mKeys[event.keyname].mOnFrameMove = on_frame_move
                            inst.mCreator.mEventSystem:AddEventListener(
                                "FrameMove",
                                on_frame_move,
                                inst.mOnKeyPressed.mKeys[event.keyname]
                            )
                        end
                    end
                end
            end
            Mod.mEventSystem:AddEventListener("handleKeyEvent", self.mOnKeyPressed.mFunction, self)
        end
        self.mOnKeyPressed.mKeys[parameters] = self.mOnKeyPressed.mKeys[parameters] or {}
        self.mOnKeyPressed.mKeys[parameters].mFunction = func
    elseif "OnClick" == name then
        if not self.mOnClick then
            self.mOnClick = {}
            self.mOnClick.mFunction = function(entity, event)
                if self.mOnClick.mAPI then
                    self.mOnClick.mAPI.mAlive = false
                    self.mOnClick.mAPI = nil
                end
                local new_api = API:new({mEntity = self.mEntity, mCreator = self.mCreator})
                local coro =
                    coroutine.create(
                    function()
                        func(new_api)
                    end
                )
                local function on_frame_move(key)
                    if key.mCoroutine then
                        if "suspended" == coroutine.status(key.mCoroutine) then
                            coroutine.resume(key.mCoroutine)
                        elseif "dead" == coroutine.status(key.mCoroutine) then
                            self.mCreator.mEventSystem:RemoveEventListener("FrameMove", key.mOnFrameMove, key)
                            key.mOnFrameMove = nil
                        end
                    end
                end
                self.mOnClick.mCoroutine = coro
                self.mOnClick.mAPI = new_api
                if not self.mOnClick.mOnFrameMove then
                    self.mOnClick.mOnFrameMove = on_frame_move
                    self.mCreator.mEventSystem:AddEventListener("FrameMove", on_frame_move, self.mOnClick)
                end
            end
            self.mEntity.onclick = self.mOnClick.mFunction
        end
    elseif "OnEvent" == name then
        if not self.mOnEvent then
            self.mOnEvent = {mKeys = {}}
        end
        self.mOnEvent.mKeys[parameters] = self.mOnEvent.mKeys[parameters] or {}
        self.mOnEvent.mKeys[parameters].mFunction = func
    end
end
function API:sendEvent(event)
    if self.mOnEvent and self.mOnEvent.mKeys[event] then
        self.mOnEvent.mKeys[event].mFunction()
    end
end
function API:postEvent(event)
    if self.mOnEvent and self.mOnEvent.mKeys[event] then
        local func = self.mOnEvent.mKeys[event].mFunction
        local new_api = API:new({mEntity = self.mEntity, mCreator = self.mCreator})
        local coro =
            coroutine.create(
            function()
                func(new_api)
            end
        )
        local function on_frame_move(key)
            if key.mCoroutine then
                if "suspended" == coroutine.status(key.mCoroutine) then
                    coroutine.resume(key.mCoroutine)
                elseif "dead" == coroutine.status(key.mCoroutine) then
                    self.mCreator.mEventSystem:RemoveEventListener("FrameMove", key.mOnFrameMove, key)
                    key.mOnFrameMove = nil
                end
            end
        end
        self.mOnEvent.mKeys[event].mCoroutine = coro
        self.mOnEvent.mKeys[event].mAPI = new_api
        if not self.mOnEvent.mKeys[event].mOnFrameMove then
            self.mOnEvent.mKeys[event].mOnFrameMove = on_frame_move
            self.mCreator.mEventSystem:AddEventListener("FrameMove", on_frame_move, self.mOnEvent.mKeys[event])
        end
    end
end
function API:say(text, time)
    self.mCommandQueue:add(CommandFactory.create("Say", {mEntity = self.mEntity, mText = text, mTime = time}))
    coroutine.yield()
end
function API:show()
    self.mCommandQueue:add(CommandFactory.create("SetVisible", {mEntity = self.mEntity, mVisible = true}))
    coroutine.yield()
end
function API:hide()
    self.mCommandQueue:add(CommandFactory.create("SetVisible", {mEntity = self.mEntity, mVisible = false}))
    coroutine.yield()
end
function API:setTime(time)
    self.mCommandQueue:add(CommandFactory.create("SetTime", {mEntity = self.mEntity, mTime = time}))
    coroutine.yield()
end
function API:setAnimation(animationID)
    self.mCommandQueue:add(CommandFactory.create("SetAnimation", {mEntity = self.mEntity, mAnimationID = animationID}))
    coroutine.yield()
end
function API:setSize(size)
    self.mCommandQueue:add(CommandFactory.create("SetSize", {mEntity = self.mEntity, mSize = size}))
    coroutine.yield()
end
function API:wait(time)
    self.mCommandQueue:add(CommandFactory.create("Wait", {mEntity = self.mEntity, mTime = time}))
    coroutine.yield()
end
function API:stop()
    self.mCommandQueue:add(CommandFactory.create("Stop", {mEntity = self.mEntity, mAPI = self}))
    coroutine.yield()
end
function API:playSound(path)
    self.mCommandQueue:add(CommandFactory.create("PlaySound", {mEntity = self.mEntity, mPath = path}))
    coroutine.yield()
end
function API:askAndWait(question)
    self.mCommandQueue:add(
        CommandFactory.create("AskAndWait", {mEntity = self.mEntity, mQuestion = question, mAPI = self})
    )
    coroutine.yield()
end
function API:getAnswer()
    return self.mAnswer
end
function API:isMouseDown()
    return Mod.mLastMouseButtonState["left"] == "Pressed"
end
function API:isKeyPressed(key)
    return Mod.mLastKeyState[key] == "Pressed"
end
function API:getMousePosition(posType)
    local result = Game.SelectionManager:GetPickingResult()
    if "x" == posType then
        return result.blockX
    elseif "y" == posType then
        return result.blockY
    elseif "z" == posType then
        return result.blockZ
    end
end
function API:getTimer()
    return self.mTimerTickCount * 0.001
end
function API:resetTimer()
    self.mCommandQueue:add(CommandFactory.create("ResetTimer", {mEntity = self.mEntity, mAPI = self}))
    coroutine.yield()
end
function API:destroyBlock()
    self.mCommandQueue:add(CommandFactory.create("DestroyBlock", {mEntity = self.mEntity}))
    coroutine.yield()
end
