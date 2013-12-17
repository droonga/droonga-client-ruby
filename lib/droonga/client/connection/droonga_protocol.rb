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
            :tag             => "droonga",
            :host            => "127.0.0.1",
            :port            => 24224,
            :connect_timeout => 1,
            :read_timeout    => 0.1,
          }
          options = default_options.merge(options)
          @logger = Fluent::Logger::FluentLogger.new(options.delete(:tag),
                                                     options)
          @connect_timeout = options[:connect_timeout]
          @read_timeout = options[:read_timeout]
        end

        def search(body, &block)
          envelope = {
            "id"         => Time.now.to_f.to_s,
            "date"       => Time.now,
            "statusCode" => 200,
            "type"       => "search",
            "body"       => body,
          }
          execute(envelope, &block)
        end

        # Sends a request message and receives one ore more response
        # messages.
        #
        # @overload execute(message, options={})
        #   Executes the request message synchronously.
        #
        #   @param message [Hash] Request message.
        #   @param options [Hash] The options to executes a request.
        #      TODO: WRITE ME
        #
        #   @return [Object] The response. TODO: WRITE ME
        #
        # @overload execute(message, options={}, &block)
        #   Executes the passed request message asynchronously.
        #
        #   @param message [Hash] Request message.
        #   @param options [Hash] The options to executes a request.
        #      TODO: WRITE ME
        #   @yield [response]
        #      The block is called when response is received.
        #   @yieldparam [Object] response
        #      The response.
        #   @yieldreturn [Boolean]
        #      true if you want to wait more responses,
        #      false otherwise.
        #
        #   @return [Request] The request object.
        def execute(message, options={}, &block)
          receiver = Receiver.new
          message = message.dup
          message["replyTo"] = "#{receiver.host}:#{receiver.port}/droonga"
          send(message, options)

          connect_timeout = options[:connect_timeout] || @connect_timeout
          read_timeout = options[:read_timeout] || @read_timeout
          receive_options = {
            :connect_timeout => connect_timeout,
            :read_timeout    => read_timeout
          }
          sync = block.nil?
          if sync
            begin
              receiver.receive(receive_options)
            ensure
              receiver.close
            end
          else
            thread = Thread.new do
              begin
                loop do
                  response = receiver.receive(receive_options)
                  break if response.nil?
                  continue_p = yield(response)
                  break unless continue_p
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

        class Receiver
          def initialize(options={})
            default_options = {
              :host            => "0.0.0.0",
              :port            => 0,
            }
            options = default_options.merge(options)
            @socket = TCPServer.new(options[:host], options[:port])
          end

          def close
            @socket.close
          end

          def host
            @socket.addr[3]
          end

          def port
            @socket.addr[1]
          end

          BUFFER_SIZE = 8192
          def receive(options={})
            responses = []
            select(@socket, options[:connect_timeout]) do
              client = @socket.accept
              unpacker = MessagePack::Unpacker.new
              select(client, options[:read_timeout]) do
                data = client.read_nonblock(BUFFER_SIZE)
                unpacker.feed_each(data) do |object|
                  responses << object
                end
              end
              client.close
            end
            # TODO: ENABLE ME
            # if responses.size >= 2
            #   responses
            # else
              responses.first
            # end
          end

          private
          def select(input, timeout)
            loop do
              start = Time.now
              readables, = IO.select([input], nil, nil, timeout)
              timeout -= (Time.now - start)
              timeout = 0 if timeout < 0
              break if readables.nil?
              yield(timeout)
            end
          end
        end
      end
    end
  end
end
