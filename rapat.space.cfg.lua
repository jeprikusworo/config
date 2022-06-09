plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/" }

-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "rapat.space";

external_service_secret = "T1kITQDBbUcTLTK3";
external_services = {
     { type = "stun", host = "rapat.space", port = 3478 },
     { type = "turn", host = "rapat.space", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
     { type = "turns", host = "rapat.space", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" }
};

cross_domain_bosh = false;
consider_bosh_secure = true;
-- https_ports = { }; -- Remove this line to prevent listening on port 5284

-- by default prosody 0.12 sends cors headers, if you want to disable it uncomment the following (the config is available on 0.12.1)
--http_cors_override = {
--    bosh = {
--        enabled = false;
--    };
--    websocket = {
--        enabled = false;
--    };
--}

-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
    protocol = "tlsv1_2+";
    ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
}

unlimited_jids = {
    "focus@auth.rapat.space",
    "jvb@auth.rapat.space"
}

VirtualHost "rapat.space"
    -- enabled = false -- Remove this line to enable this host
    authentication = "internal_plain"
    -- Properties below are modified by jitsi-meet-tokens package config
    -- and authentication above is switched to "token"
    --app_id="example_app_id"
    --app_secret="example_app_secret"
    -- Assign this host a certificate for TLS, otherwise it would use the one
    -- set in the global section (if any).
    -- Note that old-style SSL on port 5223 only supports one certificate, and will always
    -- use the global one.
    ssl = {
        key = "/etc/prosody/certs/rapat.space.key";
        certificate = "/etc/prosody/certs/rapat.space.crt";
    }
    av_moderation_component = "avmoderation.rapat.space"
    speakerstats_component = "speakerstats.rapat.space"
    conference_duration_component = "conferenceduration.rapat.space"
    -- we need bosh
    modules_enabled = {
        "bosh";
        "pubsub";
        "ping"; -- Enable mod_ping
        "speakerstats";
        "external_services";
        "conference_duration";
        "muc_lobby_rooms";
        "muc_breakout_rooms";
        "av_moderation";
    }
    c2s_require_encryption = false
    lobby_muc = "lobby.rapat.space"
    breakout_rooms_muc = "breakout.rapat.space"
    main_muc = "conference.rapat.space"
    -- muc_lobby_whitelist = { "recorder.rapat.space" } -- Here we can whitelist jibri to enter lobby enabled rooms

Component "conference.rapat.space" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
        --"token_verification";
        "muc_rate_limit";
    }
    admins = { "focus@auth.rapat.space" }
    muc_room_locking = false
    muc_room_default_public_jids = true

Component "breakout.rapat.space" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        --"token_verification";
        "muc_rate_limit";
        "polls";
    }
    admins = { "focus@auth.rapat.space" }
    muc_room_locking = false
    muc_room_default_public_jids = true

-- internal muc component
Component "internal.auth.rapat.space" "muc"
    storage = "memory"
    modules_enabled = {
        "ping";
    }
    admins = { "focus@auth.rapat.space", "jvb@auth.rapat.space" }
    muc_room_locking = false
    muc_room_default_public_jids = true

VirtualHost "auth.rapat.space"
    ssl = {
        key = "/etc/prosody/certs/auth.rapat.space.key";
        certificate = "/etc/prosody/certs/auth.rapat.space.crt";
    }
    modules_enabled = {
        "limits_exception";
    }
    authentication = "internal_hashed"

-- Proxy to jicofo's user JID, so that it doesn't have to register as a component.
Component "focus.rapat.space" "client_proxy"
    target_address = "focus@auth.rapat.space"

Component "speakerstats.rapat.space" "speakerstats_component"
    muc_component = "conference.rapat.space"

Component "conferenceduration.rapat.space" "conference_duration_component"
    muc_component = "conference.rapat.space"

Component "avmoderation.rapat.space" "av_moderation_component"
    muc_component = "conference.rapat.space"

Component "lobby.rapat.space" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
    modules_enabled = {
        "muc_rate_limit";
        "polls";
    }

-- Enabled dial-in for JaaS customers
-- Note: make sure you have the following packages installed: lua-basexx, liblua5.3-dev, libssl-dev, luarocks
-- and execute $ sudo luarocks install luajwtjitsi 3.0-0
VirtualHost "jigasi.meet.jitsi"
    enabled = false -- JaaS customers remove this line
    modules_enabled = {
      "ping";
      "bosh";
    }
    authentication = "token"
    app_id = "jitsi";
    asap_key_server = "https://jaas-public-keys.jitsi.net/jitsi-components/prod-8x8"
    asap_accepted_issuers = { "jaas-components" }
    asap_accepted_audiences = { "jigasi.rapat.space" }

VirtualHost "guest.rapat.space"
authentication = "anonymous"
c2s_require_encryption = false
