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

require "socket"
require "thread"
require "msgpack"
require "fluent-logger"

module Droonga
  class Client
    module Connection
      class DroongaProtocol
        class Request
          def initialize(thread)
            @thread = thread
          end

          def wait
            @thread.join
          end
        end

        def initialize(options={})
          default_options = {
            :tag     => "droonga",
            :host    => "127.0.0.1",
            :port    => 24224,
            :timeout => 1,
          }
          @options = default_options.merge(options)
          @logger = Fluent::Logger::FluentLogger.new(@options.delete(:tag),
                                                     @options)
          @timeout = @options[:timeout]
        end

        # Sends a request message and receives one or more response
        # messages.
        #
        # @overload reciprocate(message, options={})
        #   Sends the request message and receives one or more
        #   messages synchronously.
        #
        #   @param message [Hash] Request message.
        #   @param options [Hash] The options.
        #      TODO: WRITE ME
        #
        #   @return [Object] The response. TODO: WRITE ME
        #
        # @overload reciprocate(message, options={}, &block)
        #   Sends the request message and receives one or more
        #   response messages asynchronously.
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
        def reciprocate(message, options={}, &block)
          receiver = create_receiver
          message = message.dup
          message["replyTo"] = "#{receiver.host}:#{receiver.port}/droonga"
          send(message, options)

          sync = block.nil?
          if sync
            receive(receiver, options, &block)
          else
            thread = Thread.new do
              receive(receiver, options, &block)
            end
            Request.new(thread)
          end
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
          receiver = create_receiver
          message = message.dup
          message["from"] = "#{receiver.host}:#{receiver.port}/droonga"
          send(message, options)

          receive_options = {
            :timeout => nil,
          }
          sync = block.nil?
          if sync
            Enumerator.new do |yielder|
              loop do
                receiver.receive(receive_options) do |object|
                  yielder << object
                end
              end
            end
          else
            thread = Thread.new do
              begin
                loop do
                  receiver.receive(receive_options, &block)
                end
              ensure
                receiver.close
              end
            end
            Request.new(thread)
          end
        end

        # Sends low level request. Normally, you should use other
        # convenience methods.
        #
        # @param envelope [Hash] Request envelope.
        # @param options [Hash] The options to send request.
        #   TODO: WRITE ME
        # @return [void]
        def send(envelope, options={}, &block)
          @logger.post("message", envelope)
        end

        # Close the connection. This connection can't be used anymore.
        #
        # @return [void]
        def close
          @logger.close
        end

        private
        def create_receiver
          Receiver.new(:host => @options[:receiver_host],
                       :port => @options[:receiver_port])
        end

        def receive(receiver, options)
          timeout = options[:timeout] || @timeout

          receive_options = {
            :timeout => timeout,
          }
          begin
            responses = []
            receiver.receive(receive_options) do |response|
              responses << response
            end
            response = responses.first
            if block_given?
              yield(response)
            else
              response
            end
          ensure
            receiver.close
          end
        end

        class Receiver
          def initialize(options={})
            host = options[:host] || Socket.gethostname
            port = options[:port] || 0
            @socket = TCPServer.new(host, port)
            @read_ios = [@socket]
            @client_handlers = {}
          end

          def close
            @socket.close
            @client_handlers.each_key do |client|
              client.close
            end
          end

          def host
            @socket.addr[3]
          end

          def port
            @socket.addr[1]
          end

          BUFFER_SIZE = 8192
          def receive(options={}, &block)
            timeout = options[:timeout]
            loop do
              start = Time.new
              readable_ios, = IO.select(@read_ios, nil, nil, timeout)
              break if readable_ios.nil?
              if timeout
                timeout -= (Time.now - start)
                timeout = 0 if timeout < 0
              end
              readable_ios.each do |readable_io|
                on_readable(readable_io, &block)
              end
            end
          end

          private
          def on_readable(io)
            case io
            when @socket
              client = @socket.accept
              @read_ios << client
              @client_handlers[client] = lambda do
                unpacker = MessagePack::Unpacker.new
                data = client.read_nonblock(BUFFER_SIZE)
                unpacker.feed_each(data) do |object|
                  yield(object)
                end
                client.close
                @read_ios.delete(client)
                @client_handlers.delete(client)
              end
            else
              @client_handlers[io].call
            end
          end
        end
      end
    end
  end
end
