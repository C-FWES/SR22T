var MapTiles = {
# displays maps background from web tiles
# code from http://wiki.flightgear.org/Canvas_Snippets#A_simple_tile_map
    new : func (device, group) {
        var m = { parents: [MapTiles] };
        m.device = device;
        m.display = m.device.display.display;
        m.tile_size = 256;
        m.maps_base = getprop("/sim/fg-home") ~ '/cache/maps';
        m.makeUrl = string.compileTemplate(data['tiles-template']);
        m.makePath = string.compileTemplate(m.maps_base ~ '/{server}/{type}/{z}/{x}/{y}.{format}');
        m.num_tiles = [
            math.ceil( m.device.data.mapsize[0] / m.tile_size ) + 1,
            math.ceil( m.device.data.mapsize[1] / m.tile_size ) + 1
        ];
        m.center_tile_offset = [
            (m.num_tiles[0] - 1) / 2,
            (m.num_tiles[1] - 1) / 2
        ];
        m.visibility = m.device.role == 'MFD';
        m.group = group.createChild('group', 'tiles')
            .setTranslation(
                    m.device.role == 'MFD' ? (m.device.data.mapview[0] - m.device.data.mapsize[0] + m.device.data.mapclip.left)/2 : -520,
                    m.device.role == 'MFD' ? -250 : -45)
            .setVisible(m.visibility);
        m.tiles = setsize([], m.num_tiles[0]);
        m.last_tile = [-1,-1];
        m.last_type = data['tiles-type'];
        m.initialize_grid();
        if (m.device.role == 'PFD')
            m.device.softkeys.colored.INSETTERRAIN = 1;
        if (m.device.role == 'MFD')
            m.device.softkeys.colored.MAPTERRAIN = 1;
        return m;
    },

    off: func {
        me.group.setVisible(0);
        me.group.removeAllChildren();
        me.group.del();
    },

    setVisible : func (v) {
        if (v != me.visibility) {
            me.visibility = v;
            me.group.setVisible(v);
        }
    },

# initialize the map by setting up a grid of raster images
    initialize_grid : func {
        for(var x = 0; x < me.num_tiles[0]; x += 1) {
            me.tiles[x] = setsize([], me.num_tiles[1]);
            for(var y = 0; y < me.num_tiles[1]; y += 1)
                me.tiles[x][y] = me.group.createChild('image', 'tile ' ~ x ~ ',' ~ y);
        }
    },

# this is the callback that will be regularly called by the timer to update the map
    update : func {
         if (! me.visibility)
             return;

        var n = math.pow(2, me.device.data.zoom);
        var offset = [
            n * ((data.lon + 180) / 360) - me.center_tile_offset[0],
            (1 - math.ln(math.tan(data.lat * math.pi/180) + 1 / math.cos(data.lat * math.pi/180)) / math.pi) / 2 * n - me.center_tile_offset[1]
        ];
        var tile_index = [int(offset[0]), int(offset[1])];

        var ox = tile_index[0] - offset[0];
        var oy = tile_index[1] - offset[1];

        for (var x = 0; x < me.num_tiles[0]; x += 1)
            for(var y = 0; y < me.num_tiles[1]; y += 1)
                me.tiles[x][y]
                    .setTranslation(
                        int((ox + x) * me.tile_size + 0.5),
                        int((oy + y) * me.tile_size + 0.5));

        if (tile_index[0] != me.last_tile[0]
         or tile_index[1] != me.last_tile[1]
         or data['tiles-type'] != me.last_type) {
            for(var x = 0; x < me.num_tiles[0]; x += 1)
                for(var y = 0; y < me.num_tiles[1]; y += 1) {
                    var pos = {
                        z: me.device.data.zoom,
                        x: int(offset[0] + x),
                        y: int(offset[1] + y),
                        type: data['tiles-type'],
                        server : data['tiles-server'],
                        format: data['tiles-format'],
                        apikey: data['tiles-apikey'],
                    };

                    (func {
                        var img_path = me.makePath(pos);
                        logprint(LOG_DEBUG, 'img_path: ', img_path);
                        var tile = me.tiles[x][y];

                        if (io.stat(img_path) == nil) { # image not found, save in $FG_HOME
                            var img_url = me.makeUrl(pos);
                            logprint(LOG_DEBUG, 'requesting ' ~ img_url);
                            http.save(img_url, img_path)
                                .done(func {logprint(LOG_INFO, 'received image ' ~ img_path); tile.set("src", img_path);})
                                .fail(func (r) logprint(LOG_WARN, 'Failed to get image ' ~ img_path ~ ' ' ~ r.status ~ ': ' ~ r.reason));
                        }
                        else { # cached image found, reusing
                            logprint(LOG_DEBUG, 'loading ' ~ img_path);
                            tile.set("src", img_path);
                        }
                    })();
                }
            me.last_tile = tile_index;
            me.last_type = data['tiles-type'];
        }
    },
};
