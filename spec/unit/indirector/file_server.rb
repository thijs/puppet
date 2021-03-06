#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-19.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/indirector/file_server'
require 'puppet/file_serving/configuration'

describe Puppet::Indirector::FileServer do

    before :each do
        Puppet::Indirector::Terminus.stubs(:register_terminus_class)
        @model = mock 'model'
        @indirection = stub 'indirection', :name => :mystuff, :register_terminus_type => nil, :model => @model
        Puppet::Indirector::Indirection.stubs(:instance).returns(@indirection)

        @file_server_class = Class.new(Puppet::Indirector::FileServer) do
            def self.to_s
                "Testing::Mytype"
            end
        end

        @file_server = @file_server_class.new

        @uri = "puppet://host/my/local/file"
        @configuration = mock 'configuration'
        Puppet::FileServing::Configuration.stubs(:create).returns(@configuration)

        @request = Puppet::Indirector::Request.new(:myind, :mymethod, @uri)
    end

    describe Puppet::Indirector::FileServer, " when finding files" do

        it "should use the path portion of the URI as the file name" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil)
            @file_server.find(@request)
        end

        it "should use the FileServing configuration to convert the file name to a fully qualified path" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil)
            @file_server.find(@request)
        end

        it "should pass the node name to the FileServing configuration if one is provided" do
            @configuration.expects(:file_path).with("my/local/file", :node => "testing")
            @request.node = "testing"
            @file_server.find(@request)
        end

        it "should return nil if no fully qualified path is found" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns(nil)
            @file_server.find(@request).should be_nil
        end

        it "should return an instance of the model created with the full path if a file is found" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns("/some/file")
            instance = stub("instance", :collect => nil)
            @model.expects(:new).returns instance
            @file_server.find(@request).should equal(instance)
        end
    end

    describe Puppet::Indirector::FileServer, " when returning instances" do
        before :each do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns("/some/file")
            @instance = stub 'instance', :collect => nil
        end

        it "should create the instance with the path at which the instance was found" do
            @model.expects(:new).with { |key, options| key == "/some/file" }.returns @instance
            @file_server.find(@request)
        end

        it "should set the provided :links setting on to the instance if one is provided" do
            @model.expects(:new).returns(@instance)
            @instance.expects(:links=).with(:mytest)
            @request.options[:links] = :mytest
            @file_server.find(@request)
        end

        it "should not set a :links value if no :links parameter is provided" do
            @model.expects(:new).returns(@instance)
            @file_server.find(@request)
        end

        it "should collect each instance's attributes before returning" do
            @instance.expects(:collect)
            @model.expects(:new).returns @instance
            @file_server.find(@request)
        end
    end

    describe Puppet::Indirector::FileServer, " when checking authorization" do

        it "should have an authorization hook" do
            @file_server.should respond_to(:authorized?)
        end

        it "should deny the :destroy method" do
            @request.method = :destroy
            @file_server.authorized?(@request).should be_false
        end

        it "should deny the :save method" do
            @request.method = :save
            @file_server.authorized?(@request).should be_false
        end
        
        describe "and finding file information" do
            before do
                @request.method = :find 
            end

            it "should use the file server configuration to determine authorization" do
                @configuration.expects(:authorized?)
                @file_server.authorized?(@request)
            end

            it "should pass the file path from the URI to the file server configuration" do
                @configuration.expects(:authorized?).with { |uri, *args| uri == "my/local/file" }
                @file_server.authorized?(@request)
            end

            it "should pass the node name to the file server configuration" do
                @configuration.expects(:authorized?).with { |key, options| options[:node] == "mynode" }
                @request.node = "mynode"
                @file_server.authorized?(@request)
            end

            it "should pass the IP address to the file server configuration" do
                @configuration.expects(:authorized?).with { |key, options| options[:ipaddress] == "myip" }
                @request.ip = "myip"
                @file_server.authorized?(@request)
            end

            it "should return false if the file server configuration denies authorization" do
                @configuration.expects(:authorized?).returns(false)
                @file_server.authorized?(@request)
            end

            it "should return true if the file server configuration approves authorization" do
                @configuration.expects(:authorized?).returns(true)
                @file_server.authorized?(@request)
            end
        end
    end

    describe Puppet::Indirector::FileServer, " when searching for files" do

        it "should use the path portion of the URI as the file name" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil)
            @file_server.search(@request)
        end

        it "should use the FileServing configuration to convert the file name to a fully qualified path" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil)
            @file_server.search(@request)
        end

        it "should pass the node name to the FileServing configuration if one is provided" do
            @configuration.expects(:file_path).with("my/local/file", :node => "testing")
            @request.node = "testing"
            @file_server.search(@request)
        end

        it "should return nil if no fully qualified path is found" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns(nil)
            @file_server.search(@request).should be_nil
        end

        it "should use :path2instances from the terminus_helper to return instances if a module is found and the file exists" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns("my/file")
            @file_server.expects(:path2instances)
            @file_server.search(@request)
        end

        it "should pass the request on to :path2instances" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns("my/file")
            @file_server.expects(:path2instances).with(@request, "my/file").returns []
            @file_server.search(@request)
        end

        it "should return the result of :path2instances" do
            @configuration.expects(:file_path).with("my/local/file", :node => nil).returns("my/file")
            @file_server.expects(:path2instances).with(@request, "my/file").returns :footest
            @file_server.search(@request).should == :footest
        end
    end
end
