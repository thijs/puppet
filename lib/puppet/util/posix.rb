# Utility methods for interacting with POSIX objects; mostly user and group
module Puppet::Util::POSIX

    # Retrieve a field from a POSIX Etc object.  The id can be either an integer
    # or a name.  This only works for users and groups.  It's also broken on
    # some platforms, unfortunately.
    def get_posix_field(space, field, id)
        unless id
            raise ArgumentError, "Did not get id"
        end
        if id =~ /^\d+$/
            id = Integer(id)
        end
        if id.is_a?(Integer)
            if id > Puppet[:maximum_uid].to_i
                Puppet.err "Tried to get %s field for silly id %s" % [field, id]
                return nil
            end
            method = idmethod(space)
        else
            method = namemethod(space)
        end
        
        begin
            return Etc.send(method, id).send(field)
        rescue ArgumentError => detail
            # ignore it; we couldn't find the object
            return nil
        end
    end

    # A degenerate method of retrieving name/id mappings.  The job of this method is
    # to find a specific entry and then return a given field from that entry.
    def search_posix_field(type, field, id)
        idmethod = idfield(type)
        integer = false
        if id =~ /^\d+$/
            id = Integer(id)
        end
        if id.is_a?(Integer)
            integer = true
            if id > Puppet[:maximum_uid].to_i
                Puppet.err "Tried to get %s field for silly id %s" % [field, id]
                return nil
            end
        end

        Etc.send(type) do |object|
            if integer and object.send(idmethod) == id
                return object.send(field)
            elsif object.name == id
                return object.send(field)
            end
        end

        # Apparently the group/passwd methods need to get reset; if we skip
        # this call, then new users aren't found.
        case type
        when :passwd: Etc.send(:endpwent)
        when :group: Etc.send(:endgrent)
        end
        return nil
    end
    
    # Look in memory for an already-managed type and use its info if available.
    # Currently unused.
    def get_provider_value(type, field, id)
        unless typeklass = Puppet::Type.type(type)
            raise ArgumentError, "Invalid type %s" % type
        end
        
        id = id.to_s
        
        chkfield = idfield(type)
        obj = typeklass.find { |obj|
            if id =~ /^\d+$/
                obj.should(chkfield).to_s == id ||
                    obj.provider.send(chkfield) == id
            else 
                obj[:name] == id
            end                    
        }
        
        return nil unless obj
        
        if obj.provider
            begin
                val = obj.provider.send(field)
                if val == :absent
                    return nil
                else
                    return val
                end
            rescue => detail
                if Puppet[:trace]
                    puts detail.backtrace
                    Puppet.err detail
                    return nil
                end
            end
        end
    end
    
    # Determine what the field name is for users and groups.
    def idfield(space)
        case Puppet::Util.symbolize(space)
        when :gr, :group: return :gid
        when :pw, :user, :passwd: return :uid
        else
            raise ArgumentError.new("Can only handle users and groups")
        end
    end
    
    # Determine what the  get method by id is for users and groups.
    def idmethod(space)
      case Puppet::Util.symbolize(space)
      when :gr, :group: return :getgrgid
      when :pw, :user, :passwd: return :getpwuid
      else
          raise ArgumentError.new("Can only handle users and groups")
      end
    end

    # Determine what the  get method by name is for users and groups.
    def namemethod(space)
      case Puppet::Util.symbolize(space)
      when :gr, :group: return :getgrnam
      when :pw, :user, :passwd: return :getpwnam
      else
          raise ArgumentError.new("Can only handle users and groups")
      end
    end
    
    # Get the GID of a given group from the name
    def gid(groupname)
        gid = get_posix_field(:group, :gid, groupname)
        if groupname != get_posix_field(:group, :name, gid)
          search_posix_field(:group, :gid, groupname)
        else
          gid
        end
    end

    # Get the UID of a given user from the name
    def uid(username)
        uid = get_posix_field(:passwd, :uid, username)
        if username != get_posix_field(:passwd, :name, uid)
          search_posix_field(:passwd, :uid, username)
        else
          uid
        end
    end
    
    # get the name of a given user from the uid
    def username(uid)
      name = get_posix_field(:passwd, :name, uid)
      if uid != get_posix_field(:passwd, :uid, name)
        search_posix_field(:passwd, :name, uid)
      else
        name
      end
    end
    
    # get the name of a given group from the gid
    def groupname(gid)
      name = get_posix_field(:group, :name, gid)
      if gid != get_posix_field(:group, :gid, name)
        search_posix_field(:group, :name, gid)
      else
        name
      end
    end
end

