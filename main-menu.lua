
local composer = require( "composer" )
local widget = require( "widget" )
local presetControls = require( "presetControls" )

local scene = composer.newScene()

local sndClickHandle, sndBackgroundHandle, sndBackground

local buttonGroup
local focusIndex

local platformName = system.getInfo( "platformName" )
local qrscanner = require('plugin.qrscanner')

local audioFileFormat = "ogg"
if ( platformName == "iPhone OS" or platformName == "tvOS" ) then
	audioFileFormat = "aac"
end

local webView

vonalkod=""

-- Scene button handler function
local function handleSceneButton( nextScene )
	if nextScene == "game" and next( composer.getVariable("controls") ) == nil then
		print( "You must have at least one player connected!" )
	elseif nextScene == "exit" then
		native.requestExit()
	else
		audio.play( sndClickHandle )
	--	composer.gotoScene( nextScene, { effect="slideDown", time=600 } )
	end
	return true
end

local function listener(message)
    -- message variable contains the value of a scanned QR Code or a barcode.
    --print('Scanned message:', message)
    --native.showAlert('QR Code Scanner', message, {'OK'})
    webView:request( "http://192.168.201.1/lvs/adatgyujto/main.php?vonalkod="..message )
    barcodeText.text=message
	vonalkod=""
	audio.play( sndClickHandle )

end




local function widgetHandleSceneButton( event )
	return handleSceneButton(event.target.id)
end




local function onRowRender( event )
	
	local controls = composer.getVariable("controls")

    local row = event.row
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth
    local color = event.row.params.color
    local deviceText
    if not event.row.isCategory then
	    if controls[event.row.params.id] then
	    	deviceText = event.row.params.id  .. ' / ' .. controls[event.row.params.id].name
	    	print (deviceText)
	    else
	    	deviceText = event.row.params.deviceName .. " (not configured)"
	    	color = color*0.6
	    	print (deviceText)
	    end
	else
		deviceText = event.row.params.label
	end

    local rowTitle = display.newText( row, deviceText, 0, 0, composer.getVariable("appFont"), 15 )
    rowTitle:setFillColor( color )
    rowTitle.x = rowWidth/2
    rowTitle.y = rowHeight * 0.5
end


local function updateControlsTable( device, status, deviceName )

	local controls = composer.getVariable("controls")
print("updateControlsTable")
	-- If a specific controller is connected or disconnected, update controls table
	if device and status then

		-- Handle connect
		if status == "connected" then

			print("connected:"..deviceName)
		-- Handle disconnect
		elseif status == "disconnected" then

			print("disconnected:"..deviceName)
		end

	-- Else, populate controls table with all current controllers
	else


		for i,v in pairs( controls ) do
		--	if string.find(v.name,"LI" ) then

				print("Kapcsolodva:"..v.name)
		--	end
		end

		local getEventDevice = composer.getVariable("getEventDevice")
 		local getNiceDeviceName = composer.getVariable("getNiceDeviceName")
		local inputDevices = system.getInputDevices()
		for i = 1,#inputDevices do
			local device = inputDevices[i]
			local deviceId = getEventDevice({device=device})
			 print( i .. ") " .. inputDevices[i].displayName )
			if controls[deviceId] == nil then
				
				--print("x:"..deviceName)		
				-- print( index .. ") " .. inputDevices[index].displayName )	
			end
		end


	end
end


local function onInputDeviceStatusChanged( event )

	local controls = composer.getVariable("controls")
	local getEventDevice = composer.getVariable("getEventDevice")
	local getNiceDeviceName = composer.getVariable("getNiceDeviceName")

	if event.connectionStateChanged and event.device then
		if controls[getEventDevice(event)] == nil then
			controls[getEventDevice(event)] = presetControls.presetForDevice( event.device )
		end
		if event.device.isConnected == true then
			updateControlsTable( getEventDevice(event), "connected", getNiceDeviceName(event) )
		--	print("d:"..getNiceDeviceName)
		elseif event.device.isConnected == false then
			updateControlsTable( getEventDevice(event), "disconnected", getNiceDeviceName(event) )
		end
	end
end

local function onKeyEvent( event )
	print("j")
	if event.phase ~= "down" then
		return false
	end

	-- Let Android/tvOS exit here rather than closing the app mid-handling.
	if event.keyName == "back" or event.keyName == "menu" then
		return false
	end

	local getEventDevice = composer.getVariable( "getEventDevice" )
	local getNiceDeviceName = composer.getVariable( "getNiceDeviceName" )
	local controls = composer.getVariable("controls")

	local device = getEventDevice( event )
	print("gomb:"..event.keyName)
	vonalkod= vonalkod.. event.keyName
	barcodeText.text=""
	if (vonalTimer._time ~= nil) then
		timer.cancel(vonalTimer)
	end
	vonalTimer=timer.performWithDelay( 50, vonalkodEnd, 0 )

end





function scene:create( event )

	local sceneGroup = self.view
	buttonGroup = display.newGroup()

	-- Play button
	local playButton = widget.newButton{
		x = 70,
		y = 0,
		id = "game",
		label = "Start",
		onPress = widgetHandleSceneButton,
		emboss = false,
		font = composer.getVariable("appFont"),
		fontSize = 17,
		shape = "rectangle",
		width = 150,
		height = 32,
		fillColor = {
			default={ (55/255)+(0.3), (68/255)+(0.3), (77/255)+(0.3), 1 },
			over={ (55/255)+(0.3), (68/255)+(0.3), (77/255)+(0.3), 0.8 }
		},
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } }
	}
	buttonGroup:insert( playButton )
    
	local options = 
	{
	    parent = buttonGroup,
	    text = "Barcode",     
	    x = display.contentCenterX,
	    y = 30,
	    width = 320,     --required for multi-line and alignment
	    font = native.systemFontBold,   
	    fontSize = 18,
	    align = "center"  --new alignment parameter
	}

    barcodeText = display.newText(options)

--	buttonGroup:insert( configureButton )
--	buttonGroup.y =  0 - composer.getVariable("letterboxHeight") + buttonGroup.contentHeight/2 + 45
--	sceneGroup:insert( buttonGroup )
	
	-- Exit button. Do not show on iOS or tvOS, as per Apple's guidelines
	if ( platformName ~= "iPhone OS" and platformName ~= "tvOS" ) then
		local exitButton = widget.newButton{
			x = 400,
			y = 0,
			id = "exit",
			label = "Exit",
			onPress = widgetHandleSceneButton,
			emboss = false,
			font = composer.getVariable("appFont"),
			fontSize = 17,
			shape = "rectangle",
			width = 150,
			height = 32,
			fillColor = {
				default={ (55/255)+(0.15), (68/255)+(0.15), (77/255)+(0.15), 1 },
				over={ (55/255)+(0.1), (68/255)+(0.1), (77/255)+(0.1), 0.8 }
			},
			labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } }
		}
		buttonGroup:insert( exitButton )
	end


local scanButton = widget.newButton {
			x = 235,
			y = 0,
    shape = "rectangle",
			width = 150,
			height = 32,
font = composer.getVariable("appFont"),
    fontSize = 17,
    fillColor = {
				default={ (55/255)+(0.15), (68/255)+(0.15), (77/255)+(0.15), 1 },
				over={ (55/255)+(0.1), (68/255)+(0.1), (77/255)+(0.1), 0.8 }
			},
			labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
    label = 'With Camera',
    onRelease = function()
        print('Showing scanner')
        qrscanner.show(listener, {
            symbols = {
                'aztec', 'code39', 'code39mod43', 'code93', 'code128', 'codabar',
                'databar', 'databar_exp', 'datamatrix', 'ean8', 'ean13', 'interleaved2of5',
                'itf14', 'i25', 'isbn10', 'isbn13', 'partial', 'pdf417', 'upca', 'upce','qr'
            },
            strings = {
                title = 'Vonalkód olvasó'
            },
            overlays = {
              --  searching = {
               --     filename = 'images/searching.png'
               -- },
                found = {
                    filename = 'images/found.png'
                }
            }
        })
    end}
	buttonGroup:insert( scanButton )
	buttonGroup.y =  0 - composer.getVariable("letterboxHeight") + 64
	sceneGroup:insert( buttonGroup )

	sndClickHandle = audio.loadSound( "click." .. audioFileFormat )

webView = native.newWebView( display.contentCenterX, 220, 480,200 )
webView:request( "http://192.168.201.1/lvs/adatgyujto/main.php" )

	Runtime:addEventListener( "key", onKeyEvent )
end


function math.clamp(n, low, high) return math.min(math.max(n, low), high) end

vonalTimer = {}

function vonalkodEnd( event )
	
	barcodeText.text=vonalkod
	vonalkod=""
	audio.play( sndClickHandle )
	timer.cancel(event.source)
end




function scene:show( event )

	if event.phase == "will" then

		focusIndex = 0
	print("will")
		updateControlsTable()
	elseif event.phase == "did" then
		print("did")
		Runtime:addEventListener( "key", onKeyEvent )
		Runtime:addEventListener( "inputDeviceStatus", onInputDeviceStatusChanged )

--		audio.rewind( sndBackgroundHandle )
	--	sndBackground = audio.play( sndBackgroundHandle, { loops=-1 } )

		system.activate("controllerUserInteraction")
	end
end


function scene:hide( event )

	if event.phase == "will" then
--		audio.stop( sndBackground )
		Runtime:removeEventListener( "key", onKeyEvent )
		Runtime:removeEventListener( "inputDeviceStatus", onInputDeviceStatusChanged )
	elseif event.phase == "did" then
		system.deactivate("controllerUserInteraction")
	end
end


scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene
