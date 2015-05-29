#!/usr/bin/env ruby
#
# Copyright (C) 2015 Droonga Project
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "slop"

require "droonga/client"

module Droonga
  module Command
    class MissingRequiredParameter < StandardError
    end

    class NoResponse < StandardError
    end

    class Base
      private
      def parse_options(&block)
        options = Slop.parse(:help => true) do |option|
          yield(option) if block_given?

          option.on(:"dry-run",
                    "Only reports messages to be sent to the engine.",
                    :default => false)

          option.separator("Connections:")
          option.on(:host=,
                    "Host name of the engine node.",
                    :default => Client::DEFAULT_HOST)
          option.on(:port=,
                    "Port number to communicate with the engine.",
                    :as => Integer,
                    :default => Client::DEFAULT_PORT)
          option.on(:tag=,
                    "Tag name to communicate with the engine.",
                    :default => Client::DEFAULT_TAG)
          option.on(:dataset=,
                    "Dataset name for the sending message.",
                    :default => Client::DEFAULT_DATASET)
          option.on("receiver-host=",
                    "Host name of the computer you are running this command.",
                    :default => Client::DEFAULT_HOST)
          option.on("target-role=",
                    "Role of engine nodes which should process the message.",
                    :default => Client::DEFAULT_TARGET_ROLE)
          option.on("timeout=",
                    "Time to terminate unresponsive connections, in seconds.",
                    :default => Client::DEFAULT_TIMEOUT_SECONDS)
        end
        @options = options
      rescue Slop::MissingOptionError => error
        $stderr.puts(error)
        raise MissingRequiredParameter.new
      end

      def request(message, &block)
        if @options[:"dry-run"]
          if @options[:pretty]
            puts(JSON.pretty_generate(message))
          else
            puts(JSON.generate(message))
          end
          return nil
        end

        response = nil
        open do |client|
          response = client.request(message)
        end
        yield response
      end

      def send(message)
        open do |client|
          client.send(message)
        end
      end

      def open(&block)
        options = {
          :host          => @options[:host],
          :port          => @options[:port],
          :tag           => @options[:tag],
          :protocol      => :droonga,
          :receiver_host => @options["receiver-host"],
          :receiver_port => 0,
          :default_timeout => @options[:timeout],
          :default_target_role => @options[:target_role],
        }
        Droonga::Client.open(options) do |client|
          yield(client)
        end
      end
    end
  end
end
