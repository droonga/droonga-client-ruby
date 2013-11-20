# -*- coding: utf-8 -*-
#
# Copyright (C) 2013 Droonga Project
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

require "socket"
require "msgpack"
require "fluent-logger"

require "droonga/client/version"
require "droonga/client/connection/droonga_protocol"

module Droonga
  class Client
    attr_reader :connection

    def initialize(options={})
      @connection = Connection::DroongaProtocol.new(options)
    end

    def search(body)
      @connection.search(body)
    end
  end
end
