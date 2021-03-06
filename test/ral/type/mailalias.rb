#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../lib/puppettest'

require 'puppettest'
require 'mocha'

class TestMailAlias < Test::Unit::TestCase
	include PuppetTest

    def setup
        super
        @type = Puppet::Type.type(:mailalias)

        @provider = @type.defaultprovider

        # Make sure they aren't using something funky like netinfo
        unless @provider.name == :aliases
            @type.defaultprovider = @type.provider(:aliases)
        end

        cleanup do @type.defaultprovider = nil end

        if @provider.respond_to?(:default_target=)
            @default_file = @provider.default_target
            cleanup do
                @provider.default_target = @default_file
            end
            @target = tempfile()
            @provider.default_target = @target
        end
    end

    # This isn't much of a test, but then, it's not much of a type.
    def test_recipient_arrays
        resource = @type.create(:name => "luke", :recipient => "yay", :target => tempfile)
        values = nil
        assert_nothing_raised("Could not retrieve mailalias") do
            values = resource.retrieve.inject({}) { |hash, a| hash[a[0].name] = a[1]; hash }
        end
        assert_equal(:absent, values[:recipient])
        resource.property(:recipient).expects(:set).with(%w{yay})
        assert_nothing_raised("Could not sync mailalias") do
            resource.property(:recipient).sync
        end
    end
end

