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

require "droonga/client/error"

module Droonga
  class Client
    module Connection
      # The top error class of connection module.
      class Error < Client::Error
      end

      # The error class for invalid response type is specified.
      class InvalidResponseType < Error
        attr_reader :type
        def initialize(type)
          @type = type
          super("Unknown response type: <#{@type}>. " +
                  "Available types: [:none, :one]")
        end
      end
    end
  end
end
