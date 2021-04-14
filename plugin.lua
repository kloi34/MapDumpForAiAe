-- MapDumpForAiAe

-- pls finish your maps AiAe

-- this is only a temporary plugin that's poorly commented/structured, i think i will integrate
--    this plugin with my lazymapper plugin. in lazymapper, i will implement more features,
--    structure the code a bit better, and add comments to the code

---------------------------------------------------------------------------------------------------
-- Global constants
---------------------------------------------------------------------------------------------------

SAMELINE_SPACING = 5                   -- value determining spacing between GUI items on the same row
DEFAULT_WIDGET_HEIGHT = 26             -- value determining the height of GUI widgets
BUTTON_WIDGET_WIDTH = 60               -- value determining the width of buttons

---------------------------------------------------------------------------------------------------
-- Plugin and GUI
---------------------------------------------------------------------------------------------------

-- Creates the plugin window
function draw()
    applyStyle()
    menu()
end

-- Configures GUI visual settings
function applyStyle()
    -- Plugin Styles
    local rounding = 5
    
    imgui.PushStyleVar( imgui_style_var.WindowPadding,      { 8, 8 } )
    imgui.PushStyleVar( imgui_style_var.FramePadding,       { 8, 5 }   )
    imgui.PushStyleVar( imgui_style_var.ItemSpacing,        { DEFAULT_WIDGET_HEIGHT / 2 - 1, 4 })
    imgui.PushStyleVar( imgui_style_var.ItemInnerSpacing,   { SAMELINE_SPACING, 6 })
    imgui.PushStyleVar( imgui_style_var.WindowBorderSize,   0          )
    imgui.PushStyleVar( imgui_style_var.WindowRounding,     rounding   )
    imgui.PushStyleVar( imgui_style_var.FrameRounding,      rounding   )
end

-- Creates the plugin menu
function menu()
    imgui.Begin("MapDumpForAiAe", imgui_window_flags.AlwaysAutoResize)
    state.IsWindowHovered = imgui.IsWindowHovered()
    local vars = {
        beatSnap = 8,
        startTime = 0,
        endTime = 0,
        jumpEveryBeat = false,
        allowTrills = false,
        trillFrequency = 0,
        maxTrillLength = 3,
        allowAnchors = false,
        statusMessage = "Advice: do not set snap to 1/32"
        -- allowOneHandedTrills = false,
        -- allowLongAnchorsAndTrills = false,
    }
    retrieveStateVariables(vars)
    
    if imgui.Button(" Current ", {BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        vars.startTime = state.SongTime
    end
    imgui.SameLine(0, SAMELINE_SPACING)
    imgui.PushItemWidth(BUTTON_WIDGET_WIDTH * 2)
    _, vars.startTime = imgui.InputInt("Start time", vars.startTime, 1)
    imgui.PopItemWidth()
    
    
    spacing()
    
    if imgui.Button("Current", {BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        vars.endTime = state.SongTime
    end
    imgui.SameLine(0, SAMELINE_SPACING)
    imgui.PushItemWidth(BUTTON_WIDGET_WIDTH * 2)
    _, vars.endTime = imgui.InputInt("Stop time", vars.endTime, 1)
    imgui.PopItemWidth()
    
    separator()
    spacing()
    
    imgui.AlignTextToFramePadding()
    imgui.Text("1 /")
    imgui.SameLine(0, SAMELINE_SPACING)
    imgui.PushItemWidth(BUTTON_WIDGET_WIDTH * 1.5)
    _, vars.beatSnap = imgui.InputInt("Dump Beat Snap", vars.beatSnap)
    imgui.PopItemWidth()
    vars.beatSnap = mathClamp(vars.beatSnap, 6, 32)
  
    separator()
    spacing()
    
    _, vars.jumpEveryBeat = imgui.Checkbox("Have a jump (2 notes) every beat", vars.jumpEveryBeat)
    
    separator()
    spacing()
    
    _, vars.allowTrills = imgui.Checkbox("Allow Trills", vars.allowTrills)
    if vars.allowTrills then
        spacing()
        imgui.PushItemWidth(BUTTON_WIDGET_WIDTH * 1.5)
        _, vars.trillFrequency = imgui.DragInt("Trill Frequency",
                vars.trillFrequency, 0.2, 0, 100, vars.trillFrequency.." %%")
        vars.trillFrequency = mathClamp(vars.trillFrequency, 0, 100)
        imgui.PopItemWidth()
        spacing()
        
        imgui.PushItemWidth(BUTTON_WIDGET_WIDTH * 1.5)
        _, vars.maxTrillLength = imgui.InputInt("Max # of notes in trill", vars.maxTrillLength)
        vars.maxTrillLength = mathClamp(vars.maxTrillLength, 3, 16)
        imgui.PopItemWidth()
        spacing()
        
        --_, vars.allowOneHandedTrills = imgui.Checkbox("Allow One-handed Trills", vars.allowOneHandedTrills)
        --_, vars.allowLongAnchorsAndTrills = imgui.Checkbox("Allow Long Anchors/Trills", vars.allowLongAnchorsAndTrills)
    end
    separator()
    spacing()
    
    _, vars.allowAnchors = imgui.Checkbox("Allow Anchors", vars.allowAnchors)
    separator()
    spacing()
    
    imgui.Indent(60)
    if imgui.Button("Place dump", {BUTTON_WIDGET_WIDTH * 2, DEFAULT_WIDGET_HEIGHT * 1.2}) then
        local noHitObjectsInRange = true
        for i, hitObject in pairs(map.HitObjects) do
            if isWithinRange(hitObject.StartTime, vars.startTime, vars.endTime) then
                noHitObjectsInRange = false
                vars.statusMessage = "There are already notes in the time interval, so no notes were placed   :("
                break
            end
        end
        if noHitObjectsInRange then
            vars.statusMessage = vars.statusMessage.."not in range"
            local hitObjectsToPlace = {}
            local snapCounter = 0
            local currentOffset = vars.startTime
            local avoidLanes = {}
            local availableLanes = {1, 2, 3, 4}
            local trillNoteLength = 3
            local lastFewRows = {}
            local maxAnchors = 3
            while currentOffset < vars.endTime do
                local anchorDetected = false
                local randomNum = math.random(0, 99)
                local lastFewLaneCounts = countLanes(lastFewRows)
                local candidateNotAnchorLanes = {}
                for i = 1, #lastFewLaneCounts do
                    if lastFewLaneCounts[i] < maxAnchors then
                        table.insert(candidateNotAnchorLanes, i)
                    else
                        anchorDetected = true
                        maxAnchors = 2
                    end
                end
                if not anchorDetected then
                    maxAnchors = 3
                end
                
                if vars.allowTrills and trillNoteLength <= vars.maxTrillLength and
                        randomNum < vars.trillFrequency and #avoidLanes == 2 then
                    nowAvailableLanes = table.remove(avoidLanes, 1)
                    for i = 1, #nowAvailableLanes do
                        table.insert(availableLanes, nowAvailableLanes[i])
                    end
                    trillNoteLength = trillNoteLength + 1
                else
                    trillNoteLength = 3
                end
                
                local lanes = {}
                
                if vars.jumpEveryBeat and snapCounter % vars.beatSnap == 0 then
                    local randomIndex1 = math.random(#availableLanes)
                    lanes = {availableLanes[randomIndex1]}
                    table.insert(hitObjectsToPlace, utils.CreateHitObject(math.floor(currentOffset + 0.5), lanes[1]))
                    table.remove(availableLanes, randomIndex1)
                    local randomIndex2 = math.random(#availableLanes)
                    table.insert(lanes, availableLanes[randomIndex2])
                    table.insert(hitObjectsToPlace, utils.CreateHitObject(math.floor(currentOffset + 0.5), lanes[2]))
                    table.remove(availableLanes, randomIndex2)
                elseif #availableLanes == 1 then
                    lanes = {availableLanes[1]}
                    table.insert(hitObjectsToPlace, utils.CreateHitObject(math.floor(currentOffset + 0.5), lanes[1]))
                    table.remove(availableLanes, 1)
                elseif not vars.allowAnchors then
                    local done = false
                    local availableLanesCopy = {}
                    for i = 1, #availableLanes do
                        table.insert(availableLanesCopy, availableLanes[i])
                    end
                    while not done do
                        local randomIndex = math.random(#availableLanesCopy)
                        local lane = table.remove(availableLanesCopy, randomIndex)
                        local isCandidateLane = false
                        for j = 1, #candidateNotAnchorLanes do
                            if candidateNotAnchorLanes[j] == lane then
                                isCandidateLane = true
                            end
                        end 
                        if #availableLanesCopy == 0 or isCandidateLane then
                            lanes = {lane}
                            table.insert(hitObjectsToPlace, utils.CreateHitObject(math.floor(currentOffset + 0.5), lane))
                            for k = 1, #availableLanes do
                                if availableLanes[k] == lane then
                                    table.remove(availableLanes, k)
                                end
                            end
                            done = true
                        end
                    end
                else
                    local randomIndex1 = math.random(#availableLanes)
                    lanes = {availableLanes[randomIndex1]}
                    table.insert(hitObjectsToPlace, utils.CreateHitObject(math.floor(currentOffset + 0.5), lanes[1]))
                    table.remove(availableLanes, randomIndex1)
                end
                
                table.insert(avoidLanes, lanes)
                table.insert(lastFewRows, lanes)
                while #lastFewRows > maxAnchors * 3 do
                    table.remove(lastFewRows, 1)
                end
                
                if #avoidLanes > 2 then
                    nowAvailableLanes = table.remove(avoidLanes, 1)
                    for i = 1, #nowAvailableLanes do
                        table.insert(availableLanes, nowAvailableLanes[i])
                    end
                end
                currentOffset = currentOffset + 60000/map.GetTimingPointAt(currentOffset).Bpm/vars.beatSnap
                snapCounter = snapCounter + 1
            end
            actions.PlaceHitObjectBatch(hitObjectsToPlace)
            if #hitObjectsToPlace > 0 then
                vars.statusMessage = "Notes successfully placed!   :)"
            else
                vars.statusMessage = "No notes placed   :("
            end
        end
    end
    separator()
    spacing()
    imgui.Unindent(60)
    imgui.TextWrapped(vars.statusMessage)
    
    saveStateVariables(vars)
    imgui.End()
end

-- Retrieves variables from the state
-- Parameters
--    variables : table that contains variables and values (Table)
function retrieveStateVariables(variables)
    for key, value in pairs(variables) do
        variables[key] = state.GetValue(key) or value
    end
end

-- Saves variables to the state
-- Parameters
--    variables : table that contains variables and values (Table)
function saveStateVariables(variables)
    for key, value in pairs(variables) do
        state.SetValue(key, value)
    end
end

-- Restricts a number to be within a closed interval
-- Parameters
--    number     : the number to keep within the interval
--    lowerBound : the lower bound of the interval
--    upperBound : the upper bound of the interval
function mathClamp(number, lowerBound, upperBound)
    if (number < lowerBound) then
        return lowerBound
    elseif (number > upperBound) then
        return upperBound
    else
        return number
    end
end

-- Returns whether a number is within a given range
-- Parameters
--    x          : number in question
--    lowerBound : upper bound of the range
--    upperBound : lower bound of the range
function isWithinRange(x, lowerBound, upperBound)
    return x >= lowerBound and x <= upperBound
end

function countLanes(lastFewRows)
    local laneCounts = {0,0,0,0}
    for i = 1, #lastFewRows do
        local lanes = lastFewRows[i]
        for j = 1, #lanes do
            local lane = lanes[j]
            laneCounts[lane] = laneCounts[lane] + 1
        end
    end
    return laneCounts
end

-- Adds a thin horizontal line separator on the GUI
function separator()
    spacing()
    imgui.Separator()
end

-- Adds vertical blank space on the GUI
function spacing()
    imgui.Dummy({0, 1})
end
