#!/usr/bin/env ruby

if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $puppetbase = "../.."
end

require 'puppet'
require 'puppet/autoload'
require 'puppettest'
require 'test/unit'

class TestAutoload < Test::Unit::TestCase
	include TestPuppet
    @things = []
    def self.newthing(name)
        @things << name
    end

    def self.thing?(name)
        @things.include? name
    end

    def self.clear
        @things.clear
    end

    def mkfile(name, path)
        # Now create a file to load
        File.open(path, "w") do |f|
            f.puts %{
TestAutoload.newthing(:#{name.to_s})
            }
        end
    end

    def teardown
        super
        self.class.clear
    end

    def test_load
        dir = tempfile()
        $: << dir
        cleanup do
            $:.delete(dir)
        end

        Dir.mkdir(dir)

        rbdir = File.join(dir, "yayness")

        Dir.mkdir(rbdir)

        # An object for specifying autoload
        klass = self.class

        loader = nil
        assert_nothing_raised {
            loader = Puppet::Autoload.new(klass, :yayness)
        }

        assert_equal(loader.object_id, Puppet::Autoload[klass].object_id,
                    "Did not retrieve loader object by class")

        # Make sure we don't fail on missing files
        assert_nothing_raised {
            assert_equal(false, loader.load(:mything),
                        "got incorrect return on failed load")
        }

        # Now create a couple of files for testing
        path = File.join(rbdir, "mything.rb")
        mkfile(:mything, path)
        opath = File.join(rbdir, "othing.rb")
        mkfile(:othing, opath)

        # Now try to actually load it.
        assert_nothing_raised {
            assert_equal(true, loader.load(:mything),
                        "got incorrect return on failed load")
        }

        assert(loader.loaded?(:mything), "Not considered loaded")

        assert(klass.thing?(:mything),
                "Did not get loaded thing")

        # Now clear everything, and test loadall
        assert_nothing_raised {
            loader.clear
        }

        self.class.clear

        assert_nothing_raised {
            loader.loadall
        }

        [:mything, :othing].each do |thing|
            assert(loader.loaded?(thing), "#{thing.to_s} not considered loaded")

            assert(klass.thing?(thing),
                    "Did not get loaded #{thing.to_s}")
        end
    end

    def test_loadall
    end
end