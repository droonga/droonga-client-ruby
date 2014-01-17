# Copyright (C) 2014 Droonga Project
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

require "net/http"
require "thread"

require "rack"

module Droonga
  class Client
    module Connection
      class HTTP
        class Request
          def initialize(thread)
            @thread = thread
          end

          def wait
            @thread.join
          end
        end

        def initialize(options={})
          @host    = options[:host] || "127.0.0.1"
          @port    = options[:port] || 80
          @timeout = options[:timeout] || 1
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
          sync = block.nil?
          if sync
            send(message, options) do |response|
              response.body
            end
          else
            thread = Thread.new do
              send(message, options) do |response|
                yield(response.body)
              end
            end
            Request.new(thread)
          end
        end

        # Subscribes something and receives zero or more published
        # messages.
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
          thread = Thread.new do
            send(message, options.merge(:read_timeout => nil)) do |response|
              response.read_body(&block)
            end
          end
          Request.new(thread)
        end

        # Sends low level request. Normally, you should use other
        # convenience methods.
        #
        # @param envelope [Hash] Request envelope.
        # @param options [Hash] The options to send request.
        #   TODO: WRITE ME
        # @return [void]
        def send(message, options={}, &block)
          http = Net::HTTP.new(@host, @port)
          open_timeout = @timeout
          read_timeout = @timeout
          open_timeout = options[:open_timeout] if options.key?(:open_timeout)
          read_timeout = options[:read_timeout] if options.key?(:read_timeout)
          http.open_timeout = open_timeout
          http.read_timeout = read_timeout
          http.start do
            get = Net::HTTP::Get.new(build_path(message), options[:headers])
            http.request(get) do |response|
              yield(response)
            end
          end
        end

        # Close the connection. This connection can't be used anymore.
        #
        # @return [void]
        def close
        end

        private
        def build_path(message)
          type = nil
          parameters = {}
          message.each do |key, value|
            if key == "type"
              type = value
            else
              parameters[key] = value
            end
          end
          base_path = "/#{type}"
          if parameters.empty?
            base_path
          else
            "#{base_path}?#{Rack::Utils.build_nested_query(parameters)}"
          end
        end
      end
    end
  end
end
