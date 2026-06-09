local lines = {}
table.insert(lines, "--- FULL WORKSPACE STRUCTURE ---")

local function buildHierarchy(parent, indentLevel)
    local indentation = string.rep("    ", indentLevel)
    
    for _, child in ipairs(parent:GetChildren()) do
        -- Add the current object to our lines table
        table.insert(lines, indentation .. "↳ " .. child.Name .. " (" .. child.ClassName .. ")")
        
        -- Recursively scan this object's children
        buildHierarchy(child, indentLevel + 1)
    end
end

-- 1. Scan the workspace (starts at 0 indentation)
buildHierarchy(workspace, 0)

-- 2. Combine all recorded lines into one massive string separated by newlines
local outputString = table.concat(lines, "\n")

-- 3. Write to the file
if writefile then
    writefile("Workspace_Dump.txt", outputString)
    print("Success! The structure has been saved to 'Workspace_Dump.txt' in your executor's workspace folder.")
else
    warn("Error: The 'writefile' function is not supported in this environment.")
end
