#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require 'uri'
require 'puppet/file_serving'

# This module is used to pick the appropriate terminus
# in file-serving indirections.  This is necessary because
# the terminus varies based on the URI asked for.
module Puppet::FileServing::IndirectionHooks
    PROTOCOL_MAP = {"puppet" => :rest, "file" => :file}

    # Pick an appropriate terminus based on the protocol.
    def select_terminus(request)
        # We rely on the request's parsing of the URI.

        # Short-circuit to :file if it's a fully-qualified path or specifies a 'file' protocol.
        return PROTOCOL_MAP["file"] if request.key =~ /^#{::File::SEPARATOR}/
        return PROTOCOL_MAP["file"] if request.protocol == "file"

        # We're heading over the wire the protocol is 'puppet' and we've got a server name or we're not named 'puppet'
        if request.protocol == "puppet" and (request.server or Puppet.settings[:name] != "puppet")
            return PROTOCOL_MAP["puppet"]
        end

        if request.protocol and PROTOCOL_MAP[request.protocol].nil?
            raise(ArgumentError, "URI protocol '%s' is not currently supported for file serving" % request.protocol)
        end

        # If we're still here, we're using the file_server or modules.

        # This is the backward-compatible module terminus.
        modname = request.key.split("/")[0]

        if modname == "modules"
            terminus = :modules
        elsif terminus(:modules).find_module(modname, request.options[:node])
            Puppet.warning "DEPRECATION NOTICE: Found file '%s' in module without using the 'modules' mount; please prefix path with 'modules/'" % request.key
            terminus = :modules
        else
            terminus = :file_server
        end

        return terminus
    end
end
