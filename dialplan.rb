georouting {
	begin
	@no_caller_id = false
	@finish_geo = false
	@is_call_cell = false
	
	@radius = @current_route.routable.radius
	@route_id = @current_route.routable.id

	if ((@caller_id != nil) & (@caller_id.length == 10))
		@closest_store = get_stores_in_npanxx(@caller_id, @route_id, @radius)
		puts @closest_store.to_json
		if is_cellphone(@caller_id)
			#TO-DO: get actual city name - this is only a placeholder
			#caller is on cellphone -- route by zipcode
			@calling_area = "Saint George"
			
			@is_call_cell = true;
			break
			
		else
			#caller is not from cellphone -- attempt to route on npanxx
			@finish_geo = true
			break
		end
	else
		@no_caller_id = true
		break
	end
	rescue Exception => e
	puts e.inspect
	puts e.backtrace
	end
	
	if @no_caller_id
		#cannot identify callerid 
		+no_caller_id
	elsif @is_call_cell
		+cellphone_ivr
	elsif @finish_geo
		#closest store has been identified
		+route_to_store
	else		
		#route is finished and call is ready to be made
		+execute_call
	end	
}


