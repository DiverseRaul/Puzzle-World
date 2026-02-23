local function Format(Int)
	return string.format("%02i", Int)
end

local Time = {}

function Time.ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

function Time.ConvertToHMSMinutes(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	return Format(Minutes)..":"..Format(Seconds)
end

return Time
