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

require "droonga/client/connection/error"

module Droonga
  class Client
    module Connection
      class DroongaProtocol
        class BackendError < StandardError
          def initialize(error)
            super(error.inspect)
          end
        end

        attr_writer :on_error

        def initialize(options={})
          @host = options[:host] || "127.0.0.1"
          @port = options[:port] || 24224
          @tag = options[:tag] || "droonga"
          @options = options
          @backend = create_backend
          @backend.on_error = lambda do |error|
            on_error(BackendError.new(error))
          end
        end

        # Sends a request message and receives one or more response
        # messages.
        #
        # @overload request(message, options={})
        #   This is synchronously version.
        #
        #   @param message [Hash] Request message.
        #   @param options [Hash] The options.
        #      TODO: WRITE ME
        #
        #   @return [Object] The response. TODO: WRITE ME
        #
        # @overload request(message, options={}, &block)
        #   This is asynchronously version.
        #
        #   @param message [Hash] Request message.
        #   @param options [Hash] The options.
        #      TODO: WRITE ME
        #   @yield [response]
        #      The block is called when response is received.
        #   @yieldparam [Object] response
        #      The response.
        #
        #   @return [Request] The request object.
        def request(message, options={}, &block)
          @backend.request(message, options, &block)
        end

        # Subscribes something and receives zero or more published
        # messages.
        #
        # @overload subscribe(message, options={})
        #   This is enumerator version.
        #
        #   @param message [Hash] Subscribe message.
        #   @param options [Hash] The options.
        #      TODO: WRITE ME
        #
        #   @return [Enumerator] You can get a published message by
        #     #next. You can also use #each to get published messages.
        #
        # @overload subscribe(message, options={}, &block)
        #   This is asynchronously version.
        #
        #   @param message [Hash] Subscribe message.
        #   @param options [Hash] The options.
        #      TODO: WRITE ME
        #   @yield [message]
        #      The block is called when a published message is received.
        #      The block may be called zero or more times.
        #   @yieldparam [Object] message
        #      The published message.
        #
        #   @return [Request] The request object.
        def subscribe(message, options={}, &block)
          @backend.subscribe(message, options, &block)
        end

        # Sends low level request. Normally, you should use other
        # convenience methods.
        #
        # @param message [Hash] Request message.
        # @param options [Hash] The options to send request.
        #   TODO: WRITE ME
        # @return [void]
        def send(message, options={}, &block)
          @backend.send(message, options, &block)
        end

        # Close the connection. This connection can't be used anymore.
        #
        # @return [void]
        def close
          @backend.close
        end

        private
        def create_backend
          backend = @options[:backend] || :thread

          begin
            require "droonga/client/connection/droonga-protocol/#{backend}"
          rescue LoadError
            raise UnknownBackendError.new("Droonga protocol",
                                          backend,
                                          $!.message)
          end

          backend_name = backend.to_s.capitalize
          backend_class = self.class.const_get(backend_name)
          backend_class.new(@host, @port, @tag, @options)
        end

        def on_error(error)
          @on_error.call(error) if @on_error
        end
      end
    end
  end
end
