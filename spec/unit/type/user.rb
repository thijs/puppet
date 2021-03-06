#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

user = Puppet::Type.type(:user)

describe user do
    before do
        @provider = stub 'provider'
        @resource = stub 'resource', :resource => nil, :provider => @provider, :line => nil, :file => nil
    end

    it "should have a default provider inheriting from Puppet::Provider" do
        user.defaultprovider.ancestors.should be_include(Puppet::Provider)
    end

    it "should be able to create a instance" do
        user.create(:name => "foo").should_not be_nil
    end

    it "should have an allows_duplicates feature" do
        user.provider_feature(:allows_duplicates).should_not be_nil
    end

    it "should have an manages_homedir feature" do
        user.provider_feature(:manages_homedir).should_not be_nil
    end

    it "should have an manages_passwords feature" do
        user.provider_feature(:manages_passwords).should_not be_nil
    end

    it "should have a manages_solaris_rbac feature" do
        user.provider_feature(:manages_solaris_rbac).should_not be_nil
    end

    describe "instances" do
        it "should have a valid provider" do
            user.create(:name => "foo").provider.class.ancestors.should be_include(Puppet::Provider)
        end
    end

    properties = [:ensure, :uid, :gid, :home, :comment, :shell, :password, :groups, :roles, :auths, :profiles, :project, :keys]

    properties.each do |property|
        it "should have a %s property" % property do
            user.attrclass(property).ancestors.should be_include(Puppet::Property)
        end

        it "should have documentation for its %s property" % property do
            user.attrclass(property).doc.should be_instance_of(String)
        end
    end

    describe "when retrieving all current values" do
        before do
            @user = user.create(:name => "foo", :uid => 10, :gid => 10)
            @properties = {}
        end

        it "should return a hash containing values for all set properties" do
            values = @user.retrieve
            [@user.property(:uid), @user.property(:gid)].each { |property| values.should be_include(property) }
        end

        it "should set all values to :absent if the user is absent" do
            @user.property(:ensure).expects(:retrieve).returns :absent
            @user.property(:uid).expects(:retrieve).never
            @user.retrieve[@user.property(:uid)].should == :absent
        end

        it "should include the result of retrieving each property's current value if the user is present" do
            @user.property(:ensure).expects(:retrieve).returns :present
            @user.property(:uid).expects(:retrieve).returns 15
            @user.retrieve[@user.property(:uid)].should == 15
        end
    end

    describe "when managing the ensure property" do
        before do
            @ensure = user.attrclass(:ensure).new(:resource => @resource)
        end

        it "should support a :present value" do
            lambda { @ensure.should = :present }.should_not raise_error
        end

        it "should support an :absent value" do
            lambda { @ensure.should = :absent }.should_not raise_error
        end

        it "should call :create on the provider when asked to sync to the :present state" do
            @provider.expects(:create)
            @ensure.should = :present
            @ensure.sync
        end

        it "should call :delete on the provider when asked to sync to the :absent state" do
            @provider.expects(:delete)
            @ensure.should = :absent
            @ensure.sync
        end

        describe "and determining the current state" do
            it "should return :present when the provider indicates the user exists" do
                @provider.expects(:exists?).returns true
                @ensure.retrieve.should == :present
            end

            it "should return :absent when the provider indicates the user does not exist" do
                @provider.expects(:exists?).returns false
                @ensure.retrieve.should == :absent
            end
        end
    end

    describe "when managing the uid property" do
        it "should convert number-looking strings into actual numbers" do
            uid = user.attrclass(:uid).new(:resource => @resource)
            uid.should = "50"
            uid.should.must == 50
        end

        it "should support UIDs as numbers" do
            uid = user.attrclass(:uid).new(:resource => @resource)
            uid.should = 50
            uid.should.must == 50
        end

        it "should :absent as a value" do
            uid = user.attrclass(:uid).new(:resource => @resource)
            uid.should = :absent
            uid.should.must == :absent
        end
    end

    describe "when managing the gid" do
        it "should :absent as a value" do
            gid = user.attrclass(:gid).new(:resource => @resource)
            gid.should = :absent
            gid.should.must == :absent
        end

        it "should convert number-looking strings into actual numbers" do
            gid = user.attrclass(:gid).new(:resource => @resource)
            gid.should = "50"
            gid.should.must == 50
        end

        it "should support GIDs specified as integers" do
            gid = user.attrclass(:gid).new(:resource => @resource)
            gid.should = 50
            gid.should.must == 50
        end

        it "should support groups specified by name" do
            gid = user.attrclass(:gid).new(:resource => @resource)
            gid.should = "foo"
            gid.should.must == "foo"
        end

        describe "when syncing" do
            before do
                @gid = user.attrclass(:gid).new(:resource => @resource, :should => %w{foo bar})
            end

            it "should use the first found, specified group as the desired value and send it to the provider" do
                Puppet::Util.expects(:gid).with("foo").returns nil
                Puppet::Util.expects(:gid).with("bar").returns 500

                @provider.expects(:gid=).with 500

                @gid.sync
            end
        end
    end

    describe "when managing passwords" do
        before do
            @password = user.attrclass(:password).new(:resource => @resource, :should => "mypass")
        end

        it "should not include the password in the change log when adding the password" do
            @password.change_to_s(:absent, "mypass").should_not be_include("mypass")
        end

        it "should not include the password in the change log when changing the password" do
            @password.change_to_s("other", "mypass").should_not be_include("mypass")
        end
    end

    describe "when manages_solaris_rbac is enabled" do
        before do
            @provider.stubs(:satisfies?).returns(false)
            @provider.expects(:satisfies?).with(:manages_solaris_rbac).returns(true)
        end

        it "should support a :role value for ensure" do
            @ensure = user.attrclass(:ensure).new(:resource => @resource)
            lambda { @ensure.should = :role }.should_not raise_error
        end
    end
end
