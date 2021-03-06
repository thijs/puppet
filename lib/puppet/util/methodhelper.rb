# Where we store helper methods related to, um, methods.
module Puppet::Util::MethodHelper
    def requiredopts(*names)
        names.each do |name|
            if self.send(name).nil?
                devfail("%s is a required option for %s" % [name, self.class])
            end
        end
    end

    # Iterate over a hash, treating each member as an attribute.
    def set_options(options)
        options.each do |param,value|
            method = param.to_s + "="
            begin
                self.send(method, value)
            rescue NoMethodError
                raise ArgumentError, "Invalid parameter %s to object class %s" %
                        [param,self.class.to_s]
            end
        end
    end

    # Take a hash and convert all of the keys to symbols if possible.
    def symbolize_options(options)
        options.inject({}) do |hash, opts|
            if opts[0].respond_to? :intern
                hash[opts[0].intern] = opts[1]
            else
                hash[opts[0]] = opts[1]
            end
            hash
        end
    end
end
