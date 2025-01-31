GLOBAL_VAR(AdminProcCaller)
GLOBAL_PROTECT(AdminProcCaller)
GLOBAL_VAR_INIT(AdminProcCallCount, FALSE)
GLOBAL_PROTECT(AdminProcCallCount)
GLOBAL_VAR(LastAdminCalledTargetRef)
GLOBAL_PROTECT(LastAdminCalledTargetRef)
GLOBAL_VAR(LastAdminCalledTarget)
GLOBAL_PROTECT(LastAdminCalledTarget)
GLOBAL_VAR(LastAdminCalledProc)
GLOBAL_PROTECT(LastAdminCalledProc)
GLOBAL_LIST_EMPTY(AdminProcCallSpamPrevention)
GLOBAL_PROTECT(AdminProcCallSpamPrevention)


/datum/admins/proc/proccall_atom(datum/A as null|area|mob|obj|turf)
	set category = null
	set name = "Atom ProcCall"
	set waitfor = FALSE

	if(!check_rights(R_DEBUG))
		return

	var/procname = input("Proc name, eg: attack_hand", "Proc:", null) as text|null
	if(!procname)
		return

	if(!hascall(A, procname))
		to_chat(usr, "<font color='red'>Error: callproc_datum(): type [A.type] has no proc named [procname].</font>")
		return

	var/list/lst = usr.client.holder.get_callproc_args()
	if(!lst)
		return

	if(!A || !IsValidSrc(A))
		to_chat(usr, "<span class='warning'>Error: callproc_datum(): owner of proc no longer exists.</span>")
		return

	log_admin("[key_name(usr)] called [A]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
	message_admins("[ADMIN_TPMONTY(usr)] called [A]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
	admin_ticket_log(A, "[key_name_admin(usr)] called [A]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")

	var/returnval = WrapAdminProcCall(A, procname, lst) // Pass the lst as an argument list to the proc
	. = usr.client.holder.get_callproc_returnval(returnval, procname)
	if(.)
		to_chat(usr, .)


/datum/admins/proc/proccall_advanced()
	set category = "Debug"
	set name = "Advanced ProcCall"
	set waitfor = FALSE

	if(!check_rights(R_DEBUG))
		return

	var/datum/target = null
	var/targetselected = 0
	var/returnval = null

	switch(alert("Proc owned by something?",, "Yes", "No"))
		if("Yes")
			targetselected = TRUE
			var/list/value = usr.client.vv_get_value(default_class = VV_ATOM_REFERENCE, classes = list(VV_ATOM_REFERENCE, VV_DATUM_REFERENCE, VV_MOB_REFERENCE, VV_CLIENT))
			if(!value["class"] || !value["value"])
				return
			target = value["value"]
		if("No")
			target = null
			targetselected = FALSE

	var/procname = input("Proc path, eg: /proc/attack_hand(mob/living/user)")
	if(!procname)
		return

	//strip away everything but the proc name
	var/list/proclist = splittext(procname, "/")
	if(!length(proclist))
		return

	procname = proclist[length(proclist)]

	var/proctype = "proc"
	if("verb" in proclist)
		proctype = "verb"


	var/procpath
	if(targetselected && !hascall(target, procname))
		to_chat(usr, "<font color='red'>Error: callproc(): type [target.type] has no [proctype] named [procname].</font>")
		return
	else if(!targetselected)
		procpath = text2path("/[proctype]/[procname]")
		if(!procpath)
			to_chat(usr, "<font color='red'>Error: callproc(): proc [procname] does not exist. (Did you forget the /proc/ part?)</font>")
			return

	var/list/lst = usr.client.holder.get_callproc_args()
	if(!lst)
		return

	if(targetselected)
		if(!target)
			to_chat(usr, "<font color='red'>Error: callproc(): owner of proc no longer exists.</font>")
			return
		log_admin("[key_name(usr)] called [target]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
		message_admins("[ADMIN_TPMONTY(usr)] called [target]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
		admin_ticket_log(target, "[key_name(usr)] called [target]'s [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
		returnval = WrapAdminProcCall(target, procname, lst) // Pass the lst as an argument list to the proc
	else
		//this currently has no hascall protection. wasn't able to get it working.
		log_admin("[key_name(usr)] called [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
		message_admins("[ADMIN_TPMONTY(usr)] called [procname]() with [length(lst) ? "the arguments [list2params(lst)]" : "no arguments"].")
		returnval = WrapAdminProcCall(GLOBAL_PROC, procpath, lst) // Pass the lst as an argument list to the proc

	. = usr.client.holder.get_callproc_returnval(returnval, procname)
	if(.)
		to_chat(usr, .)


/datum/admins/proc/get_callproc_returnval(returnval, procname)
	. = ""
	if(islist(returnval))
		var/list/returnedlist = returnval
		. = "<font color='blue'>"
		if(length(returnedlist))
			var/assoc_check = returnedlist[1]
			if(istext(assoc_check) && (returnedlist[assoc_check] != null))
				. += "[procname] returned an associative list:"
				for(var/key in returnedlist)
					. += "\n[key] = [returnedlist[key]]"

			else
				. += "[procname] returned a list:"
				for(var/elem in returnedlist)
					. += "\n[elem]"
		else
			. = "[procname] returned an empty list"
		. += "</font>"

	else
		. = "<font color='blue'>[procname] returned: [!isnull(returnval) ? returnval : "null"]</font>"


/datum/admins/proc/get_callproc_args()
	var/argnum = input("Number of arguments", "Number:", 0) as num|null
	if(isnull(argnum))
		return

	. = list()
	var/list/named_args = list()
	while(argnum--)
		var/named_arg = input("Leave blank for positional argument. Positional arguments will be considered as if they were added first.", "Named argument") as text|null
		var/value = usr.client.vv_get_value(restricted_classes = list(VV_RESTORE_DEFAULT))
		if (!value["class"])
			return
		if(named_arg)
			named_args[named_arg] = value["value"]
		else
			. += value["value"]
	if(LAZYLEN(named_args))
		. += named_args


/datum/admins/proc/delete_all()
	set category = "Debug"
	set name = "Delete Instances"

	var/blocked = list(/obj, /obj/item, /obj/effect, /obj/machinery, /mob, /mob/living, /mob/living/carbon, /mob/living/carbon/xenomorph, /mob/living/carbon/human, /mob/dead, /mob/dead/observer, /mob/living/silicon, /mob/living/silicon/ai)
	var/chosen_deletion = input(usr, "Type the path of the object you want to delete", "Delete:") as null|text

	if(!chosen_deletion)
		return

	chosen_deletion = text2path(chosen_deletion)
	if(!ispath(chosen_deletion))
		return

	if(!ispath(/mob) && !ispath(/obj))
		to_chat(usr, "<span class = 'warning'>Only works for types of /obj or /mob.</span>")
		return

	var/hsbitem = input(usr, "Choose an object to delete.", "Delete:") as null|anything in typesof(chosen_deletion)
	if(!hsbitem)
		return

	var/do_delete = TRUE
	if(hsbitem in blocked)
		if(alert("Are you REALLY sure you wish to delete all instances of [hsbitem]? This will lead to catastrophic results!",,"Yes","No") != "Yes")
			do_delete = FALSE

	var/del_amt = 0
	if(!do_delete)
		return

	for(var/atom/O in world)
		if(istype(O, hsbitem))
			del_amt++
			qdel(O)

	log_admin("[key_name(usr)] deleted all instances of [hsbitem] ([del_amt]).")
	message_admins("[ADMIN_TPMONTY(usr)] deleted all instances of [hsbitem] ([del_amt]).")


/datum/admins/proc/generate_powernets()
	set category = "Debug"
	set name = "Generate Powernets"
	set desc = "Regenerate all powernets."

	if(!check_rights(R_DEBUG))
		return

	SSmachines.makepowernets()

	log_admin("[key_name(usr)] has remade powernets.")
	message_admins("[ADMIN_TPMONTY(usr)] has remade powernets.")


/datum/admins/proc/debug_mob_lists()
	set category = "Debug"
	set name = "Debug Mob Lists"

	var/dat

	var/choice = input("Which list?") as null|anything in list("Players", "Observers", "New Players", "Admins", "Clients", "Mobs", "Living Mobs", "Alive Mobs", "Dead Mobs", "Xenos", "Alive Xenos", "Dead Xenos", "Humans", "Alive Humans", "Dead Humans")
	if(!choice)
		return

	switch(choice)
		if("Players")
			for(var/i in GLOB.player_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Observers")
			for(var/i in GLOB.observer_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("New Players")
			for(var/i in GLOB.new_player_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Admins")
			for(var/i in GLOB.admins)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Clients")
			for(var/i in GLOB.clients)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Mobs")
			for(var/i in GLOB.mob_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Living Mobs")
			for(var/i in GLOB.mob_living_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Alive Mobs")
			for(var/i in GLOB.alive_mob_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Dead Mobs")
			for(var/i in GLOB.dead_mob_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Xenos")
			for(var/i in GLOB.xeno_mob_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Alive Xenos")
			for(var/i in GLOB.alive_xeno_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Dead Xenos")
			for(var/i in GLOB.dead_xeno_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Humans")
			for(var/i in GLOB.human_mob_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Alive Humans")
			for(var/i in GLOB.alive_human_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"
		if("Dead Humans")
			for(var/i in GLOB.dead_human_list)
				var/mob/M = i
				dat += "[M] [ADMIN_VV(M)]<br>"

	var/datum/browser/browser = new(usr, "moblists", "<div align='center'>[choice]</div>")
	browser.set_content(dat)
	browser.open(FALSE)

	log_admin("[key_name(usr)] is debugging the [choice] list.")
	message_admins("[ADMIN_TPMONTY(usr)] is debugging the [choice] list.")


/datum/admins/proc/spawn_atom(object as text)
	set category = "Debug"
	set name = "Spawn"
	set desc = "Spawn an atom."

	if(!check_rights(R_SPAWN))
		return

	if(!object)
		return

	var/list/types = typesof(/atom)
	var/list/matches = new()

	for(var/path in types)
		if(findtext("[path]", object))
			matches += path

	if(!length(matches))
		return

	var/chosen
	if(length(matches) == 1)
		chosen = matches[1]
	else
		chosen = input("Select an atom type", "Spawn Atom", matches[1]) as null|anything in matches
		if(!chosen)
			return

	if(ispath(chosen, /turf))
		var/turf/T = get_turf(usr.loc)
		T.ChangeTurf(chosen)
	else
		new chosen(usr.loc)

	log_admin("[key_name(usr)] spawned [chosen] at [AREACOORD(usr.loc)].")
	message_admins("[ADMIN_TPMONTY(usr)] spawned [chosen] at [ADMIN_VERBOSEJMP(usr.loc)].")


/datum/admins/proc/delete_atom(atom/A as obj|mob|turf in world)
	set category = null
	set name = "Delete"

	if(!check_rights(R_DEBUG))
		return

	if(alert(src, "Are you sure you want to delete: [A]?", "Delete", "Yes", "No") != "Yes")
		return

	if(QDELETED(A))
		return

	var/turf/T = get_turf(A)

	log_admin("[key_name(usr)] deleted [A]([A.type]) at [AREACOORD(T)].")
	message_admins("[ADMIN_TPMONTY(usr)] deleted [A]([A.type]) at [ADMIN_VERBOSEJMP(T)].")

	qdel(A)


/datum/admins/proc/restart_controller(controller in list("Master", "Failsafe"))
	set category = "Debug"
	set name = "Restart Controller"
	set desc = "Restart one of the various periodic loop controllers for the game (be careful!)"

	if(!check_rights(R_DEBUG))
		return

	switch(controller)
		if("Master")
			Recreate_MC()
		if("Failsafe")
			new /datum/controller/failsafe()

	log_admin("[key_name(usr)] has restarted the [controller] controller.")
	message_admins("[ADMIN_TPMONTY(usr)] has restarted the [controller] controller.")


/datum/admins/proc/check_contents()
	set category = "Debug"
	set name = "Check Contents"

	if(!check_rights(R_DEBUG))
		return

	var/mob/living/L = usr.client.holder.apicker("Check contents of:", "Check Contents", list(APICKER_CLIENT, APICKER_LIVING))
	if(!istype(L))
		return

	var/dat = "<br>"
	for(var/i in L.get_contents())
		var/atom/A = i
		dat += "[A] [ADMIN_VV(A)]<br>"

	var/datum/browser/popup = new(usr, "contents_[key_name(L)]", "<div align='center'>Contents of [key_name(L)]</div>")
	popup.set_content(dat)
	popup.open(FALSE)

	log_admin("[key_name(usr)] checked the contents of [key_name(L)].")
	message_admins("[ADMIN_TPMONTY(usr)] checked the contents of [ADMIN_TPMONTY(L)].")



/datum/admins/proc/reestablish_db_connection()
	set category = "Debug"
	set name = "Reestablish DB Connection"

	if(!check_rights(R_DEBUG))
		return

	if(!CONFIG_GET(flag/sql_enabled))
		to_chat(usr, "<span class='adminnotice'>The Database is not enabled!</span>")
		return

	if(SSdbcore.IsConnected(TRUE))
		if(alert("The database is already connected! If you *KNOW* that this is incorrect, you can force a reconnection", "The database is already connected!", "Force Reconnect", "Cancel") != "Force Reconnect")
			return

		SSdbcore.Disconnect()
		log_admin("[key_name(usr)] has forced the database to disconnect")
		message_admins("[ADMIN_TPMONTY(usr)] has forced the database to disconnect!")

	log_admin("[key_name(usr)] is attempting to re-established the DB Connection.")
	message_admins("[ADMIN_TPMONTY(usr)] is attempting to re-established the DB Connection.")

	SSdbcore.failed_connections = 0

	if(!SSdbcore.Connect())
		log_admin("Database connection failed: " + SSdbcore.ErrorMsg())
		message_admins("Database connection failed: " + SSdbcore.ErrorMsg())
	else
		log_admin("Database connection re-established!")
		message_admins("Database connection re-established!")


/datum/admins/proc/view_runtimes()
	set category = "Debug"
	set name = "View Runtimes"
	set desc = "Open the runtime Viewer"

	if(!check_rights(R_DEBUG))
		return

	GLOB.error_cache.show_to(usr.client)

	log_admin("[key_name(usr)] viewed the runtimes.")


/datum/admins/proc/spatial_agent()
	set category = "Debug"
	set name = "Spatial Agent"

	if(!check_rights(R_DEBUG))
		return

	var/mob/M = usr
	var/mob/living/carbon/human/H
	var/spatial = FALSE
	if(ishuman(M))
		H = M
		var/datum/job/J = SSjob.GetJob(H.job)
		spatial = istype(J, /datum/job/other/spatial_agent)

	if(spatial)
		log_admin("[key_name(M)] stopped being a spatial agent.")
		message_admins("[ADMIN_TPMONTY(M)] stopped being a spatial agent.")
		qdel(M)
	else
		H = new(get_turf(M))
		M.client.prefs.copy_to(H)
		M.mind.transfer_to(H, TRUE)
		var/datum/job/J = SSjob.GetJobType(/datum/job/other/spatial_agent)
		J.assign_equip(H)
		qdel(M)

		log_admin("[key_name(H)] became a spatial agent.")
		message_admins("[ADMIN_TPMONTY(H)] became a spatial agent.")
