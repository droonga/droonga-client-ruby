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

module Droonga
  class Client
    module Connection
      class DroongaProtocol
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

        def search(body)
          envelope = {
            "id"         => Time.now.to_f.to_s,
            "date"       => Time.now,
            "statusCode" => 200,
            "type"       => "search",
            "body"       => body,
          }
          send(envelope, :response => :one)
        end

        # Sends low level request. Normally, you should use other
        # convenience methods.
        #
        # @param envelope [Hash] Request envelope.
        # @param options [Hash] The options to send request.
        # @option options :response [nil, :none, :one] (nil) The response type.
        #   If you specify `nil`, it is treated as `:one`.
        # @return The response. TODO: WRITE ME
        def send(envelope, options={})
          response_type = options[:response] || :one
          case response_type
          when :none
            @logger.post("message", envelope)
          when :one
            receiver = Receiver.new
            begin
              envelope = envelope.dup
              envelope["replyTo"] = "#{receiver.host}:#{receiver.port}/droonga"
              @logger.post("message", envelope)
              receiver.receive(:connect_timeout => @connect_timeout,
                               :read_timeout    => @read_timeout)
            ensure
              receiver.close
            end
          else
            raise InvalidResponseType.new(response_type)
          end
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
