/obj/machinery/atmospherics/portables_connector
	icon = 'icons/atmos/connector.dmi'
	icon_state = "map_connector"

	name = "Connector Port"
	desc = "For connecting portables devices related to atmospherics control."

	dir = SOUTH
	initialize_directions = SOUTH

	var/obj/machinery/portable_atmospherics/connected_device

	var/obj/machinery/atmospherics/node

	var/datum/pipe_network/network

	var/on = 0
	use_power = 0
	level = 1


/obj/machinery/atmospherics/portables_connector/New()
	initialize_directions = dir
	..()

/obj/machinery/atmospherics/portables_connector/update_icon()
	icon_state = "connector"

/obj/machinery/atmospherics/portables_connector/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		add_underlay(T, node, dir)

/obj/machinery/atmospherics/portables_connector/hide(var/i)
	update_underlays()

/obj/machinery/atmospherics/portables_connector/process()
	..()
	if(!on)
		return
	if(!connected_device)
		on = 0
		return
	return 1

// Housekeeping and pipe network stuff below
/obj/machinery/atmospherics/portables_connector/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)
	if(reference == node)
		network = new_network

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	return null

/obj/machinery/atmospherics/portables_connector/Dispose()
	if(connected_device)
		connected_device.disconnect()
	if(node)
		node.disconnect(src)
		del(network)
	node = null
	. = ..()

/obj/machinery/atmospherics/portables_connector/initialize()
	if(node) return

	var/node_connect = dir

	for(var/obj/machinery/atmospherics/target in get_step(src,node_connect))
		if(target.initialize_directions & get_dir(target,src))
			var/c = check_connect_types(target,src)
			if (c)
				target.connected_to = c
				src.connected_to = c
				node = target
				break

	update_icon()
	update_underlays()

/obj/machinery/atmospherics/portables_connector/build_network()
	if(!network && node)
		network = new /datum/pipe_network()
		network.normal_members += src
		network.build_network(node, src)


/obj/machinery/atmospherics/portables_connector/return_network(obj/machinery/atmospherics/reference)
	build_network()

	if(reference==node)
		return network

	if(reference==connected_device)
		return network

	return null

/obj/machinery/atmospherics/portables_connector/reassign_network(datum/pipe_network/old_network, datum/pipe_network/new_network)
	if(network == old_network)
		network = new_network

	return 1

/obj/machinery/atmospherics/portables_connector/return_network_air(datum/pipe_network/reference)
	var/list/results = list()
	return results

/obj/machinery/atmospherics/portables_connector/disconnect(obj/machinery/atmospherics/reference)
	if(reference==node)
		del(network)
		node = null

	update_underlays()

	return null


/obj/machinery/atmospherics/portables_connector/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if(!iswrench(W))
		return ..()
	if(connected_device)
		user << "<span class='warning'>You cannot unwrench [src], dettach [connected_device] first.</span>"
		return 1
	if(locate(/obj/machinery/portable_atmospherics, loc))
		return 1

	playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)
	user.visible_message("<span class='notice'>[user] begins unfastening [src].</span>",
	"<span class='notice'>You begin unfastening [src].</span>")
	if(do_after(user, 40, TRUE, 5, BUSY_ICON_BUILD))
		playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)
		user.visible_message("<span class='notice'>[user] unfastens [src].</span>",
		"<span class='notice'>You unfasten [src].</span>")
		new /obj/item/pipe(loc, make_from = src)
		cdel(src)
