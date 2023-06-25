local attachedObjects = {}

addEventHandler("onClientResourceStart", resourceRoot, function()
	setTimer(triggerServerEvent, 1000, 1, "requestAttachments", localPlayer)

	setTimer(loadAttachments, 1000, 1)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
	saveAttachments()
end)

addEvent("attachObject", true)
addEventHandler("attachObject", root, function(attachData)
    if not attachedObjects[source] then
        attachedObjects[source] = {}
    end

	local attachmentId = attachData[1]
    local bone, x, y, z, rx, ry, rz, sx, sy, sz = attachData[3], attachData[4], attachData[5], attachData[6], attachData[7], attachData[8], attachData[9], attachData[10], attachData[11], attachData[12]
	local object = createObject(attachData[2], x, y, z, rx, ry, rz)
	setElementInterior(object, getElementInterior(source))
	setElementDimension(object, getElementDimension(source))

	exports.bone_attach:attachElementToBone(object, source, bone, x, y, z, rx, ry, rz)
	setElementDoubleSided(object, true)
    setTimer(setObjectScale, 100, 1, object, sx, sy, sz)

	attachedObjects[source][attachmentId] = object
end)

addEvent("attachObjectsFromSave", true)
addEventHandler("attachObjectsFromSave", root, function(saveData)
    if not attachedObjects[source] then
        attachedObjects[source] = {}
    end

	for k, attachData in pairs(saveData) do
		local attachmentId = attachData[1]
		local bone, x, y, z, rx, ry, rz, sx, sy, sz = attachData[3], attachData[4], attachData[5], attachData[6], attachData[7], attachData[8], attachData[9], attachData[10], attachData[11], attachData[12]
		local object = createObject(attachData[2], x, y, z, rx, ry, rz)
		setElementInterior(object, getElementInterior(source))
		setElementDimension(object, getElementDimension(source))

		exports.bone_attach:attachElementToBone(object, source, bone, x, y, z, rx, ry, rz)
		setTimer(setObjectScale, 100, 1, object, sx, sy, sz)

		attachedObjects[source][attachmentId] = object
	end
end)

addEvent("detachObject", true)
addEventHandler("detachObject", root, function(id)
    if id == "all" then
        for k, v in pairs(attachedObjects[source]) do
            if isElement(v) then
                exports.bone_attach:detachElementFromBone(v)
                destroyElement(v)
            end
            attachedObjects[source][k] = nil
        end

        attachedObjects[source] = nil
	elseif tonumber(id) then
		local id = tonumber(id)
        local object = attachedObjects[source][id]

        if isElement(object) then
            exports.bone_attach:detachElementFromBone(object)
            destroyElement(object)
		end
        attachedObjects[source][id] = nil
    end
end)


addEvent("receiveAttachments", true)
addEventHandler("receiveAttachments", root, function(data)
	for source, attachments in pairs(data) do
		for aId, attachData in pairs(attachments) do

			if not attachedObjects[source] then
				attachedObjects[source] = {}
			end

			local attachmentId = attachData[1]
			local bone, x, y, z, rx, ry, rz = attachData[3], attachData[4], attachData[5], attachData[6], attachData[7], attachData[8], attachData[9]
			local object = createObject(attachData[2], x, y, z, rx, ry, rz)


			exports.bone_attach:attachElementToBone(object, source, bone, x, y, z, rx, ry, rz)

			attachedObjects[source][attachmentId] = object
		end
	end
end)

addEventHandler("onClientPlayerQuit", root, function()
	if attachedObjects[source] then
		for k, v in pairs(attachedObjects[source]) do
			if isElement(v) then
				destroyElement(v)
			end
			attachedObjects[source][k] = nil
		end
		attachedObjects[source] = nil
	end
end)

local dimensionChanges = {}
local interiorChanges = {}

addEventHandler("onClientPreRender", root, function()
	for player, objects in pairs(attachedObjects) do
		if isElement(player) and getElementType(player) == "player" then
			local playerDim = getElementDimension(player)
			if not dimensionChanges[player] then
				dimensionChanges[player] = playerDim	
			end

			if dimensionChanges[player] ~= playerDim then
				for k, object in pairs(objects) do
					setElementDimension(object, playerDim)
				end

				dimensionChanges[player] = playerDim
			end

			local playerInt = getElementInterior(player)
			if not interiorChanges[player] then
				interiorChanges[player] = playerInt	
			end

			if interiorChanges[player] ~= playerInt then
				for k, object in pairs(objects) do
					setElementInterior(object, playerInt)
				end

				interiorChanges[player] = playerInt
			end
		end
	end
end)

function saveAttachments()
	if fileExists("attachments.dat") then
		fileDelete("attachments.dat")
	end

	local data = {}

	if attachedObjects[localPlayer] then
		for attachmentId, object in pairs(attachedObjects[localPlayer]) do
			local element, bone, x, y, z, rx, ry, rz = exports.bone_attach:getElementBoneAttachmentDetails(object)
			local sx, sy, sz = getObjectScale(object)

			table.insert(data, {attachmentId, getElementModel(object), bone, x, y, z, rx, ry, rz, sx, sy, sz})
		end
	end

	local attachmentData = fileCreate("attachments.dat")
	fileWrite(attachmentData, encodeString("tea", toJSON(data), { key = "[_HEXON_DEVELOPMENT_DAT_FILE_]" }))
	fileClose(attachmentData)
	
end

function loadAttachments()
	if fileExists("attachments.dat") then
		local attachmentData = fileOpen("attachments.dat")

		if attachmentData then
			local loadedData = fileRead(attachmentData, fileGetSize(attachmentData))

			if loadedData then
				loadedData = fromJSON(decodeString("tea", loadedData, { key = "[_HEXON_DEVELOPMENT_DAT_FILE_]" }))
			end

			if loadedData then
				triggerServerEvent("attachObjectsFromSave", localPlayer, loadedData)
			end
		end

		fileClose(attachmentData)
	end
end

------------------------
--[[ User Interface ]]--
------------------------

local screenX, screenY = guiGetScreenSize()

local panelState = false

local buttons = {}
local activeButton = false

local Roboto = dxCreateFont("files/Roboto.ttf", 13, false, "proof") or "default"

local panelW, panelH = 530, 395
local panelX, panelY = (screenX - panelW) * 0.5, (screenY - panelH) * 0.5

local listW, listH = 220, 240
local listX, listY = panelX + 10, panelY + 40 + 10

local rowW, rowH = listW, 40
local rowX = panelX + 10

local imageS = 200
local imageX, imageY = panelX + panelW - imageS - 20, listY

local maxRows = math.floor(listH / rowH)
local listOffset = 0
local activeItem = 1

availableAttachments = {}

local previewObject = nil

local objectProjected = false

function togglePanel(state)
	if state then
		availableAttachments = attachments

		addEventHandler("onClientRender", root, renderPanel, true, "high")
		addEventHandler("onClientClick", root, panelClickHandler)
		addEventHandler("onClientKey", root, panelKeyHandler)

		if isElement(previewObject) then
			destroyElement(previewObject)
		end
		previewObject = createObject(availableAttachments[activeItem][2], 0, 0, 0)
		setElementDoubleSided(previewObject, true)

		setElementInterior(previewObject, getElementInterior(localPlayer))
		setElementDimension(previewObject, getElementDimension(localPlayer))

		exports.object_preview:makePreview(previewObject, imageX, imageY, imageS, imageS)
		exports.object_preview:setPositionOffsets(previewObject, 0, -0.75, 0)
	else
		removeEventHandler("onClientRender", root, renderPanel)
		removeEventHandler("onClientClick", root, panelClickHandler)
		removeEventHandler("onClientKey", root, panelKeyHandler)

		exports.object_preview:destroyPreview(previewObject)
	end

	panelState = state
end

addCommandHandler("accesorios", function()
	togglePanel(not panelState)
end)

function renderPanel()
	local cursorX, cursorY = getCursorPosition()

	buttons = {}

	if isCursorShowing() then
		absX = cursorX * screenX
		absY = cursorY * screenY
	elseif cursorIsMoving then
		cursorIsMoving = false
	else
		absX, absY = -1, -1
	end

	dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(80, 80, 80, 230))
	dxDrawRectangle(panelX, panelY + 30, panelW, 3, tocolor(80, 200, 120, 230))
	dxDrawText("Sistema de Accesorios", panelX, panelY, panelX + panelW, panelY + 30, tocolor(240, 240, 240), 1, Roboto, "center", "center")

	local i = 0
	for i = 1, maxRows do
		if availableAttachments[i + listOffset] then
			local rowY = listY + rowH * (i - 1)
			local attachment = availableAttachments[i + listOffset]

			if activeItem == i + listOffset then
				dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(80, 200, 120, 140))
			elseif i % 2 == 0 then
				dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(50, 50, 50, 150))
			else
				dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(50, 50, 50, 230))
			end

			local str = "(" .. i + listOffset .. ") " .. attachment[3]
			if attachedObjects[localPlayer] then
				if attachedObjects[localPlayer][i + listOffset] then
					str = str .. " (Equipado)"
				end
			end


			dxDrawText(str, rowX + 5, rowY, rowW, rowH + rowY, tocolor(255, 255, 255), 0.8, Roboto, "left", "center")

			buttons["item:" .. i + listOffset] = {rowX, rowY, rowW, rowH}
		end
	end

	local attachmentNum = #availableAttachments

	if attachmentNum > maxRows then
		local trackSize = listH
		dxDrawRectangle(listX + listW - 5, listY, 5, trackSize, tocolor(40, 40, 40, 125))
		dxDrawRectangle(listX + listW - 5, listY + listOffset * (trackSize / attachmentNum), 5, trackSize / attachmentNum * maxRows, tocolor(80, 200, 120))
	end

	if activeItem then
		if not objectProjected then
			exports.object_preview:setProjection(previewObject, imageX, imageY, imageS, imageS)
			objectProjected = true
		else
			if isElement(previewObject) then
				exports.object_preview:drawPreview(previewObject)
			end
		end

		if cursorIsMoving then
			local rx, ry, rz = getElementRotation(previewObject)
			exports.object_preview:setRotation(previewObject, 0, 0, 360 * cursorX)

			if absX >= screenX then
				setCursorPosition(0, screenY * 0.5)
			elseif absX <= 0 then
				setCursorPosition(screenX, screenY * 0.5)
			end

            if not getKeyState("mouse1") then
				cursorIsMoving = false
				setCursorPosition(screenX * 0.5, screenY * 0.5)
                setCursorAlpha(255)
            end
        elseif cursorInBox(imageX, imageY, imageS, imageS) and getKeyState("mouse1") then
            cursorIsMoving = true
            setCursorAlpha(0)
            setCursorPosition(screenX * 0.5, screenY * 0.5)
        end

		--dxDrawImage(imageX, imageY, imageS, imageS, "files/" .. availableattachments[activeItem] .. ".png")
	end

	dxDrawButton("button:exit", panelX + panelW - 120 - 10, panelY + panelH - 30 - 10, 120, 30, "Salir")
	dxDrawButton("button:select", panelX + 10, panelY + panelH - 30 - 10, 120, 30, "Seleccionar")

	if attachedObjects[localPlayer] then
		dxDrawButton("button:remove:all", panelX + 10 + 120 + 10, panelY + panelH - 30 - 10, 120, 30, "Quitar todo")

		if attachedObjects[localPlayer][activeItem] then
			dxDrawButton("button:remove:" .. activeItem, panelX + 10 + (120 + 10) * 2, panelY + panelH - 30 - 10, 120, 30, "Quitar")
		end
	end

	dxDrawText("Created by Hexon\n(www.facebook.com/hexondev)", listX, listY + listH + 20, listX + listW, listY + listH + 20, tocolor(240, 240, 240), 0.6, Roboto, "center")

	activeButton = false

	if isCursorShowing() then
		for k, v in pairs(buttons) do
			if absX >= v[1] and absX <= v[1] + v[3] and absY >= v[2] and absY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function panelClickHandler(button, state)
	if activeButton then
		if state == "down" then
			if button == "left" then
				local data = split(activeButton, ":")

				if data[2] then
					if data[1] == "button" then
						if data[2] == "exit" then
							togglePanel(false)
						elseif data[2] == "select" then
							if attachedObjects[localPlayer] then
								if attachedObjects[localPlayer][activeItem] then
									return outputChatBox("You can not attach this item because it is attached to you", 255, 0, 0)
								end
							end

							local boneId = availableAttachments[activeItem][1]
							local modelId = availableAttachments[activeItem][2]

							toggleEditor(true, activeItem)
							togglePanel(false)
						
						elseif data[2] == "remove" then
							local attachmentId = data[3]

							triggerServerEvent("detachObject", localPlayer, attachmentId)
						end
					elseif data[1] == "item" then
						activeItem = tonumber(data[2])
						setElementModel(previewObject, availableAttachments[activeItem][2])
						exports.object_preview:setPositionOffsets(previewObject, 0, -0.75, 0)
					end
				end
			end
		end
	end
end

function panelKeyHandler(button, press)
	if button == "mouse_wheel_up" and press then
		if listOffset > 0 then
			listOffset = listOffset - 1
		end
	elseif button == "mouse_wheel_down" and press then
		if listOffset < #availableAttachments - maxRows then
			listOffset = listOffset + 1
		end
	end
end

function dxDrawButton(id, x, y, w, h, text)
	dxDrawRectangle(x, y, w, h, tocolor(60, 60, 60, 230))

	local color = activeButton == id and tocolor(80, 200, 120, 230) or tocolor(150, 150, 150, 230)

	dxDrawRectangle(x, y, w, 1, color) -- top
	dxDrawRectangle(x, y + h - 1, w, 1, color) -- bottom
	dxDrawRectangle(x, y, 1, h, color) -- left
	dxDrawRectangle(x + w, y, 1, h, color) -- right

	dxDrawText(text, x, y, x + w, y + h, tocolor(230, 230, 230), 0.75, Roboto, "center", "center")

	buttons[id] = {x, y, w, h}
end

function cursorInBox(x, y, w, h)
	if x and y and w and h then
		if isCursorShowing() then
			if not isMTAWindowActive() then
				local cursorX, cursorY = getCursorPosition()

				cursorX, cursorY = cursorX * screenX, cursorY * screenY

				if cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
					return true
				end
			end
		end
	end

	return false
end

function replaceModel(modelID, txdName, dffName, alphaTransparency)
	if txdName then
		if fileExists("models/" .. txdName .. ".txd") then
			local txd = engineLoadTXD("models/" .. txdName .. ".txd")
			engineImportTXD(txd, modelID)
		end
	end
	
	if dffName then
		if fileExists("models/" .. dffName .. ".dff") then
			local dff = engineLoadDFF("models/" .. dffName .. ".dff")
			engineReplaceModel(dff, modelID, alphaTransparency or false)
		end
	end
end

for k, v in pairs(attachments) do
	replaceModel(v[2], v[4], v[5])
end