#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/indirector/file_content/file_server'
require 'shared_behaviours/file_server_terminus'

describe Puppet::Indirector::FileContent::FileServer, " when finding files" do
    it_should_behave_like "Puppet::Indirector::FileServerTerminus"

    before do
        @terminus = Puppet::Indirector::FileContent::FileServer.new
        @test_class = Puppet::FileServing::Content
    end
end
