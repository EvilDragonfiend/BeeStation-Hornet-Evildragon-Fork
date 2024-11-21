/datum/animate_master
    var/atom/owner
    var/list/animate_data = list()


/datum/animate_master/proc/add_new_animate(idx=null)
    if(isnull(idx))
        idx = length(animate_data)
    
/datum/animate_master/proc/remove(idx)
    var/datum/animate_single_data/target = animate_data[idx]
    animate_data -= target
    target.nullify_data()

/datum/animate_master/proc/stop_animate()
    animate(owner)

/datum/animate_master/proc/start_animate(need_reset=FALSE)
    if(need_reset)
        stop_animate()
    for(var/datum/animate_single_data/anim_data as anything in animate_data)
        animate()

/datum/animate_single_data/proc/set_animate(\
    /* Ah, superfun. live with it. */ \
    Object = null, \
    alpha = null, \
    color = null, \
    glide_size = null, \
    infra_luminosity = null, \
    layer = null, \
    maptext_width = null, \
    maptext_height = null, \
    maptext_x = null, \
    maptext_y = null, \
    luminosity = null, \
    pixel_x = null, \
    pixel_y = null, \
    pixel_w = null, \
    pixel_z = null, \
    matrix/transform = null, \
    dir = null, \
    icon = null, \
    icon_state = null, \
    invisibility = null, \
    maptext = null, \
    suffix = null, \
    space = null, \
    filters = null, \
    time = null, \
    loop = null, \
    easing = null, \
    flags = null, \
    delay = null\
    )

/datum/animate_single_data
    var/atom/Object = null
    var/alpha
    var/color
    var/glide_size
    var/infra_luminosity
    var/layer
    var/maptext_width
    var/maptext_height
    var/maptext_x
    var/maptext_y
    var/luminosity
    var/pixel_x
    var/pixel_y
    var/pixel_w
    var/pixel_z
    var/matrix/transform

    var/dir
    var/icon
    var/icon_state
    var/invisibility
    var/maptext
    var/suffix

    var/space // color space

    var/time
    var/loop
    var/easing
    var/flags
    var/delay // 515

    var/filters

/datum/animate_single_data/proc/nullify_data()
    Object = alpha = color = glide_size = infra_luminosity = layer = maptext_width = maptext_height = maptext_x = maptext_y = luminosity = pixel_x = pixel_y = pixel_w = pixel_z = matrix/transform = dir = icon = icon_state = invisibility = maptext = suffix = space = filters = time = loop = easing = flags = delay = null
