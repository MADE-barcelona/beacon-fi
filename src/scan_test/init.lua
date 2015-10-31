-- set ESP8266 to station mode to enable scanning
wifi.setmode(wifi.STATION)
--timer index for scanning function = 2 

--initialize variables with default values
local time_between_scans = 1000    -- interval between scans (timer index 2)
local found_open = false
local hide_and_seek = false
local signal_strength = -100
local previous_signal_strength= -100


--Function which iterates through the list of APs generated by the scan, and identifies the 'best AP'
function parse_AP_list(list_of_APs)
	previous_signal_strength = signal_strength  --updates previous strength 
	temp_strongest_signal = -100 --resets temp_strongest_signal between scans
	strongest_AP = '' --resets strongest SSID between scans
	for ssid,characteristics in pairs(list_of_APs) do
		authmode, rssi, bssid, channel = string.match(characteristics, "(%d),(-?%d+),(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x),(%d+)")  --for each AP in list, pushes AP properties into var names
		
		if (hide_and_seek = true) then                         --first thing we check if we are already in hide_and_seek mode
			if (string.sub(ssid,1,string.len(3))=="ESP") then  --check if current AP is a hide_and_seek AP i.e. if it starts with 'ESP'
				if (rssi > temp_strongest_signal) then         --SSID starts with 'ESP';  is it the strongest hide_and_seek signal we have seen in the list?
					temp_strongest_signal = rssi               --yes, SSID starts with 'ESP' and it is the strongest signal, so we set temp_strongest_signal and strongest_AP 
					strongest_AP = ssid
				end
			end
		
		elseif (string.sub(ssid,1,string.len(3))=="ESP") then  --not in hide_and_seek mode; checks if current APs SSID starts with 'ESP'
			hide_and_seek = true                               --SSID starts with 'ESP'; we activate hide_and_seek mode and afterwards we don't have to iterate through the rest of the if/else tree!
			--print('Hide-and-seek mode activated')
			temp_strongest_signal = rssi                       --as this is the first time we've found a hide_and_seek cache, we don't check if it's the strongest one
			strongest_AP = ssid
		
		elseif (found_open = true) then                        --not in hide_and_seek mode & current SSID doesn't start with 'ESP'; check if we've previously detected an open network
			if (authmode=="0") then                            --check if current AP is open
				if (rssi > temp_strongest_signal) then		   --check if current open AP is the strongest open signal we've seen so far this scan
					temp_strongest_signal = rssi               
					strongest_AP = ssid
				end
			end
				
		else then                        --not in hide_and_seek mode & current SSID doesn't start with 'ESP' & haven't previously seen open APs; check if current AP is open
			if (authmode=="0") then		 --check if current AP is open
			found_open = true            --current AP is open; no hide_and_seek mode & first time seeing open WiFi, so we set found_open to true
			--print('Found open network') 
				temp_strongest_signal = rssi --as it is the first time we find an open AP 
				strongest_AP = ssid
			end
		else then                    -- if we can't detect any open networks, reset found_open
			found_open = false
			--print ('No open networks detected')
		end		
	--if we detect an AP which fulfills our criteria, we print the SSID and RSSI of the strongest appropriate signal (one per scan)
	--if (strongest_AP~='') then  
		--io.write("Strongest AP:\t", strongest_AP, "\tSignal strength (dB):\t", temp_strongest_signal,"\tSmoothed value:\t", (signal_strength + previous_signal_strength) / 2,"\n")
	--end
end


-- Function which scans for available WiFi networks every xxx ms, then sends the resulting list to the parse_AP_list function
function scan_WiFi()
	wifi.sta.getap(parse_AP_list) --actually runs the scan
end

tmr.alarm(2, time_between_scans, 1, scan_WiFi)     --starts timer ( [on index 2], [after time_between_scans ms], [repeating] , [running scan_WiFi function])
