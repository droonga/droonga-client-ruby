# -*- coding: utf-8 -*-
#
# Copyright (C) 2013-2014 Droonga Project
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

require "droonga/client/version"
require "droonga/client/error"
require "droonga/client/connection/droonga_protocol"

module Droonga
  class Client
    class << self
      # Opens a new connection and yields a {Client} object to use the
      # connection. The client is closed after the given block is
      # finished.
      #
      # @param (see #initialize)
      #
      # @yield [client] Gives the opened client. It is alive while yielding.
      # @yieldparam client [Client] The opened client.
      #
      # @return The return value from the given block.
      def open(options={})
        client = new(options)
        begin
          yield(client)
        ensure
          client.close
        end
      end
    end

    attr_reader :connection

    # Creates a new Droonga Engine client.
    #
    # @param options [Hash] Options to connect Droonga Engine.
    # @option options [String] :tag ("droonga") The tag of the request message.
    # @option options [String] :host ("127.0.0.1")
    #   The host name or IP address of the Droonga Engine to be connected.
    # @option options [Integer] :port (24224)
    #   The port number of the Droonga Engine to be connected.
    # @option options [Integer] :timeout (5)
    #   The timeout value for connecting to, writing to and reading
    #   from Droonga Engine.
    def initialize(options={})
      @connection = Connection::DroongaProtocol.new(options)
    end

    def shuttle(message, &block)
      @connection.shuttle(message, &block)
    end

    def search(body, &block)
      shuttle({
                "id"   => Time.now.to_f.to_s,
                "date" => Time.now,
                "type" => "search",
                "body" => body,
              },
              &block)
    end

    # Close the connection used by the client. You can't send any
    # request anymore.
    #
    # @return [void]
    def close
      @connection.close
    end
  end
end
