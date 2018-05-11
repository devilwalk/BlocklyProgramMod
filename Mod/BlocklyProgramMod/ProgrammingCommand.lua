NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local function assert(boolean, errorMessage)
    if not boolean then
        echo("devilwalk--------------------------------------assert:" .. (errorMessage or ""))
    end
end

local Command = commonlib.inherit(commonlib.EventSystem, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand"))
Command.EState = {Unstart = 0, Executing = 1, Finish = 2}
function Command:ctor()
    self.mState = Command.EState.Unstart
end
function Command:execute()
    self.mState = Command.EState.Executing
end
function Command:frameMove()
    if self.mState == Command.EState.Unstart then
        self:execute()
    elseif self.mState == Command.EState.Executing then
        self:executing()
    elseif self.mState == Command.EState.Finish then
        self:finish()
    end
end
function Command:executing()
end
function Command:finish()
    echo("devilwalk--------------------------------------------debug:Command:finish")
    self:DispatchEventByType("Finish", {})
end
function Command:stop()
    echo("devilwalk--------------------------------------------debug:Command:stop")
end
--[[
    new Move({
        mContext={
            mEntity=xxxx,
            mDistance=xxxx
        }
    });
]]
local Move = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Move"))
function Move:ctor()
    assert(self.mContext ~= nil, "command move context is nil")
    assert(self.mContext.mEntity ~= nil, "command move entity is nil")
    assert(self.mContext.mDistance ~= nil, "command move distance is nil")
end
function Move:execute()
    local src_block_pos_x, src_block_pos_y, src_block_pos_z = self.mContext.mEntity:GetBlockPos()
    local dst_block_pos_x = src_block_pos_x
    local dst_block_pos_y = src_block_pos_y
    local dst_block_pos_z = src_block_pos_z
    if -0.5 < self.mContext.mEntity:GetFacing() and 0.5 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_x = src_block_pos_x + self.mContext.mDistance
    elseif 1.07 < self.mContext.mEntity:GetFacing() and 2.07 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_z = dst_block_pos_z - self.mContext.mDistance
    elseif 2.64 < self.mContext.mEntity:GetFacing() and 3.64 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_x = src_block_pos_x - self.mContext.mDistance
    elseif -2.07 < self.mContext.mEntity:GetFacing() and -1.07 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_z = dst_block_pos_z + self.mContext.mDistance
    else
        assert(false, "entity facing is error:" .. tostring(self.mContext.mEntity:GetFacing()))
    end
    self.mContext.mDestBlockPosition = {dst_block_pos_x, dst_block_pos_y, dst_block_pos_z}
    self.mContext.mEntity:WalkTo(dst_block_pos_x, dst_block_pos_y, dst_block_pos_z)
    self._super.execute(self)
    echo(
        "devilwalk--------------------------------------------debug:Move:execute:src_block_pos:" ..
            tostring(src_block_pos_x) .. "," .. tostring(src_block_pos_y) .. "," .. tostring(src_block_pos_z)
    )
    echo(
        "devilwalk--------------------------------------------debug:Move:execute:dst_block_pos:" ..
            tostring(dst_block_pos_x) .. "," .. tostring(dst_block_pos_y) .. "," .. tostring(dst_block_pos_z)
    )
end
function Move:executing()
    echo("devilwalk--------------------------------------------debug:Move:executing:self.mContext.mDestBlockPosition:")
    echo(self.mContext.mDestBlockPosition)
    echo(
        "devilwalk--------------------------------------------debug:Move:executing:self.mContext.mEntity.targetX,self.mContext.mEntity.targetY,self.mContext.mEntity.targetZ:" ..
            tostring(self.mContext.mEntity.targetX) ..
                "," .. tostring(self.mContext.mEntity.targetY) .. "," .. tostring(self.mContext.mEntity.targetZ)
    )
    if not self.mContext.mEntity:HasTarget() then
        self.mContext.mEntity:SetBlockPos(
            self.mContext.mDestBlockPosition[1] + 1,
            self.mContext.mDestBlockPosition[2],
            self.mContext.mDestBlockPosition[3]
        )
        self.mContext.mEntity:SetBlockPos(
            self.mContext.mDestBlockPosition[1],
            self.mContext.mDestBlockPosition[2],
            self.mContext.mDestBlockPosition[3]
        )
        self.mState = Command.EState.Finish
    end
end
function Move:stop()
    echo("devilwalk--------------------------------------------debug:Move:stop")
    self.mContext.mEntity:SetBlockTarget()
end

local Goto = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Goto"))
function Goto:ctor()
    assert(self.mContext ~= nil, "command goto context is nil")
    assert(self.mContext.mEntity ~= nil, "command goto entity is nil")
    assert(self.mContext.mX ~= nil, "command goto x is nil")
    assert(self.mContext.mY ~= nil, "command goto y is nil")
    assert(self.mContext.mZ ~= nil, "command goto z is nil")
end
function Goto:execute()
    self.mContext.mEntity:WalkTo(self.mContext.mX, self.mContext.mY, self.mContext.mZ)
    self._super.execute(self)
end
function Goto:executing()
    echo("devilwalk--------------------------------------------debug:Goto:executing")
    if not self.mContext.mEntity:HasTarget() then
        self.mContext.mEntity:SetBlockPos(self.mContext.mX + 1, self.mContext.mY, self.mContext.mZ)
        self.mContext.mEntity:SetBlockPos(self.mContext.mX, self.mContext.mY, self.mContext.mZ)
        self.mState = Command.EState.Finish
    end
end
function Goto:stop()
    echo("devilwalk--------------------------------------------debug:Goto:stop")
    self.mContext.mEntity:SetBlockTarget()
end

local SetPosition =
    commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.SetPosition"))
function SetPosition:ctor()
    assert(self.mContext ~= nil, "command SetPosition context is nil")
    assert(self.mContext.mEntity ~= nil, "command SetPosition entity is nil")
    assert(self.mContext.mX ~= nil, "command SetPosition x is nil")
    assert(self.mContext.mY ~= nil, "command SetPosition y is nil")
    assert(self.mContext.mZ ~= nil, "command SetPosition z is nil")
end
function SetPosition:execute()
    self.mContext.mEntity:SetBlockPos(self.mContext.mX, self.mContext.mY, self.mContext.mZ)
    self._super.execute(self)
end
function SetPosition:executing()
    echo("devilwalk--------------------------------------------debug:SetPosition:executing")
    self.mState = Command.EState.Finish
end

--[[
    new Move({
        mContext={
            mEntity=xxxx,
            mType=xxxx
        }
    });
]]
local Turn = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Turn"))
Turn.EType = {Left = 0, Right = 1, Back = 2}
function Turn:ctor()
    assert(self.mContext ~= nil, "command turn context is nil")
    assert(self.mContext.mEntity ~= nil, "command turn entity is nil")
    assert(self.mContext.mType ~= nil, "command turn type is nil")
end
function Turn:execute()
    echo(
        "devilwalk--------------------------------------------debug:Turn:execute:src_facing:" ..
            tostring(self.mContext.mEntity:GetFacing())
    )
    local delta_facing = 0
    if self.mContext.mType == Turn.EType.Left then
        delta_facing = -1.57
    elseif self.mContext.mType == Turn.EType.Right then
        delta_facing = 1.57
    elseif self.mContext.mType == Turn.EType.Back then
        delta_facing = 3.14
    else
        assert(false, "turn type error:" .. tostring(self.mContext.mType))
    end
    self.mContext.mEntity:SetFacingDelta(delta_facing)
    self._super.execute(self)
    echo(
        "devilwalk--------------------------------------------debug:Turn:execute:dst_facing:" ..
            tostring(self.mContext.mEntity:GetFacing())
    )
end
function Turn:executing()
    self.mState = Command.EState.Finish
end

local Say = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Say"))
function Say:ctor()
    assert(self.mContext ~= nil, "command say context is nil")
    assert(self.mContext.mEntity ~= nil, "command say entity is nil")
    assert(self.mContext.mText ~= nil, "command say text is nil")
    assert(self.mContext.mTime ~= nil, "command say time is nil")
end
function Say:execute()
    self.mTimer = self.mTimer or commonlib.Timer:new()
    self.mTimer:Tick()
    self.mFirstTick = self.mTimer.lastTick
    self.mContext.mEntity:Say(self.mContext.mText, self.mContext.mTime)
    self._super.execute(self)
end
function Say:executing()
    self.mTimer:Tick()
    local delta = self.mTimer.lastTick - self.mFirstTick
    if delta * 1000 >= self.mContext.mTime then
        self.mState = Command.EState.Finish
    end
end

local SetVisible = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.SetVisible"))
function SetVisible:ctor()
    assert(self.mContext ~= nil, "command SetVisible context is nil")
    assert(self.mContext.mEntity ~= nil, "command SetVisible entity is nil")
    assert(self.mContext.mVisible ~= nil, "command SetVisible visible is nil")
end
function SetVisible:execute()
    self.mContext.mEntity:SetVisible(self.mContext.mVisible)
    self._super.execute(self)
end
function SetVisible:executing()
    self.mState = Command.EState.Finish
end

local SetTime = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.SetTime"))
function SetTime:ctor()
    assert(self.mContext ~= nil, "command SetTime context is nil")
    assert(self.mContext.mTime ~= nil, "command SetTime time is nil")
end
function SetTime:execute()
    CommandManager:RunCommand("time", tostring(self.mContext.mTime))
    self._super.execute(self)
end
function SetTime:executing()
    self.mState = Command.EState.Finish
end

local SetAnimation =
    commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.SetAnimation"))
function SetAnimation:ctor()
    assert(self.mContext ~= nil, "command SetAnimation context is nil")
    assert(self.mContext.mEntity ~= nil, "command SetAnimation entity is nil")
    assert(self.mContext.mAnimationID ~= nil, "command SetAnimation mAnimationID is nil")
end
function SetAnimation:execute()
    self.mContext.mEntity:SetAnimation(self.mContext.mAnimationID)
    self._super.execute(self)
end
function SetAnimation:executing()
    self.mState = Command.EState.Finish
end

local SetSize = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.SetSize"))
function SetSize:ctor()
    assert(self.mContext ~= nil, "command SetSize context is nil")
    assert(self.mContext.mEntity ~= nil, "command SetSize entity is nil")
    assert(self.mContext.mSize ~= nil, "command SetSize mSize is nil")
end
function SetSize:execute()
    self.mContext.mEntity:SetScaling(self.mContext.mSize)
    self._super.execute(self)
end
function SetSize:executing()
    self.mState = Command.EState.Finish
end

local Wait = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Wait"))
function Wait:ctor()
    assert(self.mContext ~= nil, "command Wait context is nil")
    assert(self.mContext.mTime ~= nil, "command Wait mTime is nil")
end
function Wait:execute()
    self.mTimer = self.mTimer or commonlib.Timer:new()
    self.mTimer:Tick()
    self.mFirstTick = self.mTimer.lastTick
    self._super.execute(self)
end
function Wait:executing()
    self.mTimer:Tick()
    local delta = self.mTimer.lastTick - self.mFirstTick
    if delta * 1000 >= self.mContext.mTime then
        self.mState = Command.EState.Finish
    end
end

local Stop = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Stop"))
function Stop:ctor()
    assert(self.mContext ~= nil, "command stop context is nil")
    assert(self.mContext.mEntity ~= nil, "command stop entity is nil")
    assert(self.mContext.mAPI ~= nil, "command stop api is nil")
end
function Stop:execute()
    self.mContext.mEntity:SetDead()
    self.mContext.mAPI.mAlive = false
    self._super.execute(self)
end
function Stop:executing()
    self.mState = Command.EState.Finish
end

local PlaySound = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.PlaySound"))
function PlaySound:ctor()
    assert(self.mContext ~= nil, "command PlaySound context is nil")
    assert(self.mContext.mPath ~= nil, "command PlaySound mPath is nil")
end
function PlaySound:execute()
    CommandManager:RunCommand("sound", self.mContext.mPath)
    self._super.execute(self)
end
function PlaySound:executing()
    self.mState = Command.EState.Finish
end

local AskAndWait = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.AskAndWait"))
function AskAndWait:ctor()
    assert(self.mContext ~= nil, "command AskAndWait context is nil")
    assert(self.mContext.mQuestion ~= nil, "command AskAndWait mQuestion is nil")
    assert(self.mContext.mAPI ~= nil, "command AskAndWait mAPI is nil")
end
function AskAndWait:execute()
    self.mContext.mAPI.mAnswer = nil
    --show the ask ui
    self._super.execute(self)
end
function AskAndWait:executing()
    if self.mContext.mAPI.mAnswer then
        self.mState = Command.EState.Finish
    end
end

local ResetTimer = commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.ResetTimer"))
function ResetTimer:ctor()
    assert(self.mContext ~= nil, "command ResetTimer context is nil")
    assert(self.mContext.mAPI ~= nil, "command ResetTimer mAPI is nil")
end
function ResetTimer:execute()
    self.mContext.mAPI.mTimerTickCount = 0
    self.mContext.mAPI.mTimer:Tick()
    self.mContext.mAPI.mTimerInitTickCount = self.mContext.mAPI.mTimer.lastTick
    self._super.execute(self)
end
function ResetTimer:executing()
    self.mState = Command.EState.Finish
end

local DestroyBlock =
    commonlib.inherit(Command, commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.DestroyBlock"))
function DestroyBlock:ctor()
    assert(self.mContext ~= nil, "command turn context is nil")
    assert(self.mContext.mEntity ~= nil, "command turn entity is nil")
end
function DestroyBlock:executing()
    NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua")
    local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
    local src_block_pos_x, src_block_pos_y, src_block_pos_z = self.mContext.mEntity:GetBlockPos()
    src_block_pos_y = src_block_pos_y
    local dst_block_pos_x = src_block_pos_x
    local dst_block_pos_y = src_block_pos_y
    local dst_block_pos_z = src_block_pos_z
    if -0.5 < self.mContext.mEntity:GetFacing() and 0.5 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_x = src_block_pos_x + 1
    elseif 1.07 < self.mContext.mEntity:GetFacing() and 2.07 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_z = dst_block_pos_z - 1
    elseif 2.64 < self.mContext.mEntity:GetFacing() and 3.64 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_x = src_block_pos_x - 1
    elseif -2.07 < self.mContext.mEntity:GetFacing() and -1.07 > self.mContext.mEntity:GetFacing() then
        dst_block_pos_z = dst_block_pos_z + 1
    else
        assert(false, "entity facing is error:" .. tostring(self.mContext.mEntity:GetFacing()))
    end
    BlockEngine:SetBlockToAir(dst_block_pos_x, dst_block_pos_y, dst_block_pos_z, 3)
    self.mState = Command.EState.Finish
    echo(
        "devilwalk--------------------------------------------debug:DestroyBlock:execute:dst_block_pos:" ..
            tostring(dst_block_pos_x) .. "," .. tostring(dst_block_pos_y) .. "," .. tostring(dst_block_pos_z)
    )
end

local Factory = commonlib.gettable("Mod.BlocklyProgramMod.ProgrammingCommand.Factory")
function Factory.create(className, context)
    return Mod.BlocklyProgramMod.ProgrammingCommand[className]:new({mContext = context})
end
