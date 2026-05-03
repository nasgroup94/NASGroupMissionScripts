TTSJob = {}
TTSJob.__index = TTSJob

function TTSJob:New(config)
    config = config or {}

    local self = setmetatable({}, TTSJob)

    self.TTS = assert(config.TTS, "TTSJob requires config.TTS")
    self.Text = config.Text or "Help"
    self.Name = config.Name or "TTSJob"
    self.RequestDelay = config.RequestDelay or 1
    self.PollDelay = config.PollDelay or 1

    -- Upstream TTS voice options
    self.Voice = config.Voice
    self.Rate = config.Rate
    self.Pitch = config.Pitch

    -- SRS ExternalAudio options
    self.Freqs = config.Freqs or "250.0"
    self.Modulations = config.Modulations or "AM"
    self.Coalition = config.Coalition or 2
    self.Port = config.Port or 5002
    self.Gender = config.Gender
    self.Volume = config.Volume

    self.JobId = nil
    self.Requested = false
    self.Completed = false
    self.Failed = false

    self.Filename = nil
    self.Folder = nil
    self.Error = nil
    self.Status = nil

    self.OnQueued = config.OnQueued
    self.OnComplete = config.OnComplete
    self.OnError = config.OnError
    self.OnStatus = config.OnStatus

    return self
end

function TTSJob:Log(message)
    message = "[" .. tostring(self.Name) .. "] " .. tostring(message)

    if env and env.info then
        env.info(message)
    else
        print(message)
    end
end

function TTSJob:Request()
    if self.Requested then
        return nil
    end

    self.Requested = true

    local job_id, err = self.TTS:Request(self.Text, {
        voice = self.Voice,
        rate = self.Rate,
        pitch = self.Pitch,

        freqs = self.Freqs,
        modulations = self.Modulations,
        coalition = self.Coalition,
        port = self.Port,
        gender = self.Gender,
        volume = self.Volume,
    })

    if not job_id then
        self.Failed = true
        self.Error = err

        self:Log("TTS request failed: " .. tostring(err))

        if self.OnError then
            self.OnError(self, err)
        end

        return nil
    end

    self.JobId = job_id
    self.Status = "queued"

    self:Log("TTS job queued: " .. tostring(job_id))

    if self.OnQueued then
        self.OnQueued(self, job_id)
    end

    return nil
end


function TTSJob:Poll()
    if self.Completed or self.Failed then
        return nil
    end

    if not self.JobId then
        return timer.getTime() + self.PollDelay
    end

    local filename, folder, err, status = self.TTS:Check(self.JobId)

    self.Status = status

    if err then
        self.Failed = true
        self.Error = err

        self:Log("TTS job failed: " .. tostring(err))

        if self.OnError then
            self.OnError(self, err)
        end

        return nil
    end

    if filename then
        self.Completed = true
        self.Filename = filename
        self.Folder = folder

        self:Log("TTS job complete: " .. tostring(folder .. filename))

        if self.OnComplete then
            self.OnComplete(self, filename, folder)
        end

        return nil
    end

    if self.OnStatus then
        self.OnStatus(self, status)
    else
        self:Log("TTS job status: " .. tostring(status))
    end

    return timer.getTime() + self.PollDelay
end

function TTSJob:Start()
    timer.scheduleFunction(function()
        return self:Request()
    end, nil, timer.getTime() + self.RequestDelay)

    timer.scheduleFunction(function()
        return self:Poll()
    end, nil, timer.getTime() + self.RequestDelay + self.PollDelay)

    return self
end

return TTSJob