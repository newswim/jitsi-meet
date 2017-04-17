local st = require "util.stanza";

local token_util = module:require "token/util".new(module);

-- no token configuration but required
if token_util == nil then
    log("error", "no token configuration but it is required");
    return;
end

-- filters rayo iq in case of requested from not jwt authenticated sessions
module:hook("pre-iq/full", function(event)
    local stanza = event.stanza;
    if stanza.name == "iq" then
        local dial = stanza:get_child('dial', 'urn:xmpp:rayo:1');
        if dial then
            local session = event.origin;
            local token = session.auth_token;
            local header = dial:get_child('header');

            if token == nil
                or header.attr.name ~= 'JvbRoomName'
                or not token_util:verify_room(session, header.attr.value) then
                module:log("info",
                    "Filtering stanza dial, stanza:%s", tostring(stanza));
                session.send(st.error_reply(stanza, "auth", "forbidden"));
                return true;
            end
        end
    end
end);
