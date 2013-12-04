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
            :tag     => "droonga",
            :host    => "127.0.0.1",
            :port    => 24224,
            :timeout => 5
          }
          options = default_options.merge(options)
          @logger = Fluent::Logger::FluentLogger.new(options.delete(:tag),
                                                     options)
          @timeout = options[:timeout]
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
              receiver.receive(:timeout => @timeout)
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
              :host => "0.0.0.0",
              :port => 0,
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

          def receive(options={})
            if IO.select([@socket], nil, nil, options[:timeout])
              client = @socket.accept
              response = nil
              unpacker = MessagePack::Unpacker.new(client)
              unpacker.each do |object|
                response = object
                break
              end
              client.close
              response
            else
              nil
            end
          end
        end
      end
    end
  end
end
