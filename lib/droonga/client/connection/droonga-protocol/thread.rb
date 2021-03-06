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
        class Thread
          DEFAULT_TIMEOUT_SECONDS = 10

          attr_writer :on_error

          class ReceiverError < StandardError
            def initialize(error)
              super(error.inspect)
            end
          end

          class NilMessage < StandardError
          end

          class Request
            def initialize(thread)
              @thread = thread
            end

            def wait
              @thread.join
            end
          end

          def initialize(host, port, tag, options={})
            @host = host
            @port = port
            @tag = tag
            default_options = {
              :timeout => 1,
            }
            @options = default_options.merge(options)
            @logger = Fluent::Logger::FluentLogger.new(@tag, @options)
            @timeout = @options[:timeout]
          end

          def request(message, options={}, &block)
            receiver = create_receiver
            receiver.on_error = lambda do |error|
              on_error(ReceiverError.new(error))
            end
            message = message.dup
            message["replyTo"] = "#{receiver.host}:#{receiver.port}/droonga"
            send(message, options)

            sync = block.nil?
            if sync
              responses = []
              receive(receiver, options) do |response|
                responses << response
              end
              if responses.size > 1
                responses
              else
                responses.first
              end
            else
              thread = ::Thread.new do
                receive(receiver, options, &block)
              end
              Request.new(thread)
            end
          end

          def subscribe(message, options={}, &block)
            receiver = create_receiver
            receive_end_point = "#{receiver.host}:#{receiver.port}/droonga"
            message = message.dup
            message["replyTo"] = receive_end_point
            message["from"] = receive_end_point
            send(message, options)

            subscription_timeout = options[:subscription_timeout]
            max_messages = options[:max_messages]
            start = Time.now
            receive_options = {
              :timeout => options[:timeout] || DEFAULT_TIMEOUT_SECONDS,
            }
            n_messages = 0
            sync = block.nil?
            if sync
              Enumerator.new do |yielder|
                loop do
                  receiver.receive(receive_options) do |object|
                    yielder << object
                    n_messages += 1
                  end
                  if max_messages and
                       n_messages >= max_messages
                    break
                  end
                  if subscription_timeout
                    elapsed_seconds = Time.now - start
                    break if elapsed_seconds >= subscription_timeout
                  end
                end
                receiver.close
              end
            else
              thread = ::Thread.new do
                begin
                  loop do
                    receiver.receive(receive_options) do |message|
                      block.call(message)
                      n_messages += 1
                    end
                    if max_messages and
                         n_messages >= max_messages
                      break
                    end
                    if subscription_timeout
                      elapsed_seconds = Time.now - start
                      break if elapsed_seconds >= subscription_timeout
                    end
                  end
                ensure
                  receiver.close
                end
              end
              Request.new(thread)
            end
          end

          def send(message, options={}, &block)
            @logger.post("message", message)
          end

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
              receiver.receive(receive_options) do |response|
                yield(response)
              end
            ensure
              receiver.close
            end
          end

          def on_error(error)
            @on_error.call(error) if @on_error
          end

          class Receiver
            attr_writer :on_error

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
              catch do |tag|
                loop do
                  start = Time.now
                  readable_ios, = IO.select(@read_ios, nil, nil, timeout)
                  break if readable_ios.nil?
                  if timeout
                    timeout -= (Time.now - start)
                    timeout = 0 if timeout < 0
                  end
                  readable_ios.each do |readable_io|
                    on_readable(readable_io) do |object|
                      begin
                        yield(object)
                      rescue LocalJumpError
                        throw(tag)
                      end
                    end
                  end
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
                  begin
                    data = client.read_nonblock(BUFFER_SIZE)
                  rescue EOFError
                    client.close
                    @read_ios.delete(client)
                    @client_handlers.delete(client)
                  else
                    unpacker.feed_each(data) do |fluent_message|
                      unless fluent_message
                        on_error(NilMessage.new("thread / unpacker.feed_each"))
                      end
                      tag, time, droonga_message = fluent_message
                      unless droonga_message
                        on_error(NilMessage.new("thread / unpacker.feed_each",
                                                :fluent_message => fluent_message))
                      end
                      yield(droonga_message)
                    end
                  end
                end
              else
                @client_handlers[io].call
              end
            end

            def on_error(error)
              @on_error.call(error) if @on_error
            end
          end
        end
      end
    end
  end
end
