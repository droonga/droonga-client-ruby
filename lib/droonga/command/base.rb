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
    class Base
      private
      def parse_options(&block)
        options = Slop.parse(:help => true) do |option|
          yield(option) if block_given?

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
                    "Host name of this host.",
                    :default => Client::DEFAULT_HOST)
        end
        @options = options
      rescue Slop::MissingOptionError => error
        $stderr.puts(error)
        exit(false)
      end

      def client
        options = {
          :host          => @options[:host],
          :port          => @options[:port],
          :tag           => @options[:tag],
          :protocol      => :droonga,
          :receiver_host => @options["receiver-host"],
          :receiver_port => 0,
        }
        @client ||= Droonga::Client.new(options)
      end
    end
  end
end