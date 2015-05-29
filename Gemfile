# -*- mode: ruby; coding: utf-8 -*-
#
# Copyright (C) 2013-2015 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

source 'https://rubygems.org'

# Specify your gem's dependencies in droonga-client.gemspec
gemspec

parent_dir = File.join(File.dirname(__FILE__), "..")
grn2drn_dir = File.join(parent_dir, "grn2drn")
if File.exist?(grn2drn_dir)
  gem "grn2drn", :path => grn2drn_dir
else
  gem "grn2drn", :github => "droonga/grn2drn"
end
