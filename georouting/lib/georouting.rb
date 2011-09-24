methods_for :dialplan do

	# GEO ROUTING DIALPLAN CONTEXTS 
	
	#context to get them to store once correct zipcode has been identified
	route_to_store {
		begin
		if @closest_store != nil
		puts @closest_store['target_did']
			@channel.push(@closest_store['target_did'])
		else
			@channel.push(@number_to_dial)
		end
		rescue Exception => e
		puts e.inspect
		end
		puts @channel.to_json
		+execute_call
	}
	#cannot identify caller
	no_caller_id {
		menu "lmc/cannot_determine_callerid", :timeout => 8.seconds, :tries => 3 do |link|
			link.play_enter_zip_ivr 	1
			
			link.on_failure do
				hangup
			end
			
			link.on_invalid do 
				+no_caller_id
			end
			
			link.on_premature_timeout do |str|
				+no_caller_id
			end			
		end
	}
	
	#context cell phones first get routed to
	cellphone_ivr {
		menu "lmc/you_appear_to_be_calling_from", @calling_area, "lmc/press_1_if_correct", "lmc/press_2_to_enter_zipcode", :timeout => 8.seconds, :tries => 3 do |link|
			link.route_to_store			1
			link.play_enter_zip_ivr		2
		end	
	}
	
	#context to get zipcode from caller
	play_enter_zip_ivr {
		menu "lmc/please_enter_zipcode", :timeout => 8.seconds, :tries => 3 do |link|
			link.find_store_by_zip	00001..99999
			
			link.on_failure do
				play "please_enter_zipcode"
			end
			
			link.on_invalid do 
				play "please_enter_zipcode"
			end
			
			link.on_premature_timeout do |str|
				play "please_enter_zipcode"
			end
			
			
		end
	}
	find_store_by_zip {
		begin
		@closest_store = get_stores_by_zip(extension, @route_id, @radius)

		if @closest_store != nil
			#store found, dial target_did
			@channel.push(@closest_store.target_did)
		else
			#no store found, ring default ringto id
			@channel.push(@current_route.default_ringto_did)
		end
		rescue Exception => e
		puts e.inspect
		puts e.backtrace
		end
		+execute_call		
	}

	# END GEO ROUTING DIALPLAN CONTEXTS 


	def is_cellphone(number)
		npa = number[0..2]
		nxx = number[3..5]
		block_id = number[6]

		npanxx = Npanxx.where(:NPA => npa, :NXX => nxx, :BLOCK_ID => 'A').first
		puts "LTYPE: #{npanxx.LTYPE}"
		if npanxx.LTYPE == "C"
			return true
		else
			return false
		end

	end

	def get_stores_by_zip(zipcode, route_id, radius)
		coordinates = Npanxx.where("ZIP='#{zipcode.to_s}' OR ZIP2='#{zipcode.to_s}' OR ZIP3='#{zipcode.to_s}' OR ZIP4='#{zipcode.to_s}'").first

		lat = coordinates.latitude
		lng = coordinates.longitude
		
		store = GeoOption.near([lat, lng], radius).first
		return store
		#puts store.to_json
	end

	def get_stores_in_npanxx(caller_id, route_id, radius)
		npa = caller_id[0..2]
		nxx = caller_id[3..5]
		puts "NPA: #{npa} --- NXX: #{nxx}"
		puts "RADIUS: #{radius}"
		coordinates = Npanxx.where(:NPA => npa, :NXX => nxx).first

		store = GeoOption.near([coordinates.latitude, coordinates.longitude], radius).first

		return store
	end

end
