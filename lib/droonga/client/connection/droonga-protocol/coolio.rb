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

require "coolio"
require "droonga/message-pack-packer"

module Droonga
  class Client
    module Connection
      class DroongaProtocol
        class Coolio
          class Request
            def initialize(receiver, id, loop)
              @receiver = receiver
              @id = id
              @loop = loop
            end

            def wait
              return if @receiver.received?(@id)
              until @receiver.received?(@id)
                @loop.run_once
              end
            end
          end

          class InfiniteRequest
            def initialize(loop)
              @loop = loop
            end

            def wait
              @loop.run
            end
          end

          class Sender < ::Coolio::TCPSocket
            def initialize(*args)
              super
              @connected = false
              @buffer = []
            end

            def send(tag, data)
              fluent_message = [tag, Time.now.to_i, data]
              packed_fluent_message = MessagePackPacker.pack(fluent_message)
              if @connected
                write(packed_fluent_message)
              else
                @buffer << packed_fluent_message
              end
            end

            def on_connect
              @connected = true
              @buffer.each do |message|
                write(message)
              end
              @buffer.clear
            end
          end

          class Receiver < ::Coolio::TCPServer
            def initialize(*args)
              super(*args) do |engine|
                @engines << engine
                handle_engine(engine)
              end
              @requests = {}
              @engines = []
            end

            def close
              super
              @engines.each do |engine|
                engine.close
              end
              @engines.clear
            end

            def host
              @listen_socket.addr[3]
            end

            def port
              @listen_socket.addr[1]
            end

            def droonga_name
              "#{host}:#{port}/droonga"
            end

            def register(id, &callback)
              @requests[id] = {
                :received => false,
                :callback => callback,
              }
            end

            def unregister(id)
              @requests.delete(id)
            end

            def received?(id)
              if @requests.key?(id)
                @requests[id][:received]
              else
                true
              end
            end

            private
            def handle_engine(engine)
              unpacker = MessagePack::Unpacker.new
              on_read = lambda do |data|
                unpacker.feed_each(data) do |fluent_message|
                  tag, time, droonga_message = fluent_message
                  id = droonga_message["inReplyTo"]
                  request = @requests[id]
                  next if request.nil?
                  request[:received] = true
                  request[:callback].call(droonga_message)
                end
              end
              engine.on_read do |data|
                on_read.call(data)
              end

              on_close = lambda do
                @engines.delete(engine)
              end
              engine.on_close do
                on_close.call
              end
            end
          end

          def initialize(host, port, tag, options={})
            @host = host
            @port = port
            @tag = tag
            default_options = {
            }
            @options = default_options.merge(options)
            @loop = options[:loop] || ::Coolio::Loop.default

            @sender = Sender.connect(@host, @port)
            @sender.attach(@loop)
            @receiver_host = @options[:receiver_host] || Socket.gethostname
            @receiver_port = @options[:receiver_port] || 0
            @receiver = Receiver.new(@receiver_host, @receiver_port)
            @receiver.attach(@loop)
          end

          def request(message, options={}, &block)
            id = message["id"] || generate_id
            message = message.merge("id" => id,
                                    "replyTo" => @receiver.droonga_name)
            send(message, options)

            sync = block.nil?
            if sync
              response = nil
              block = lambda do |_response|
                response = _response
              end
            end
            @receiver.register(id) do |response|
              @receiver.unregister(id)
              block.call(response)
            end
            request = Request.new(@receiver, id, @loop)
            if sync
              request.wait
              response
            else
              request
            end
          end

          def subscribe(message, options={}, &block)
            id = message["id"] || generate_id
            message = message.merge("id" => id,
                                    "replyTo" => @receiver.droonga_name,
                                    "from" => @receiver.droonga_name)
            send(message, options)

            request = InfiniteRequest.new(@loop)
            sync = block.nil?
            if sync
              yielder = nil
              buffer = []
              @receiver.register(id) do |response|
                if yielder
                  while (old_response = buffer.shift)
                    yielder << old_response
                  end
                  yielder << response
                else
                  buffer << response
                end
              end
              Enumerator.new do |_yielder|
                yielder = _yielder
                request.wait
              end
            else
              @receiver.register(id, &block)
              request
            end
          end

          def send(message, options={}, &block)
            if message["id"].nil? or message["date"].nil?
              id = message["id"] || generate_id
              date = message["date"] || Time.now
              message = message.merge("id" => id, "date" => date)
            end
            @sender.send("#{@tag}.message", message)
          end

          def close
            @sender.close
            @receiver.close
          end

          private
          def generate_id
            Time.now.to_f.to_s
          end
        end
      end
    end
  end
end
