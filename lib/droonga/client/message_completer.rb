# -*- coding: utf-8 -*-
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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "time"

module Droonga
  class Client
    class MessageCompleter
      def initialize(options={})
        @options = options
        @fixed_date = @options[:fixed_date]
        @default_timeout = @options[:default_timeout]
      end

      def complete(message)
        id   = message["id"] || generate_id
        date = message["date"] || @fixed_date || new_date
        if not have_timeout?(message) and @default_timeout
          message["timeout"] = @default_timeout
        end
        message.merge("id" => id, "date" => date)
      end

      private
      def generate_id
        Time.now.to_f.to_s
      end

      MICRO_SECONDS_DECIMAL_PLACE = 6

      def new_date
        Time.now.utc.iso8601(MICRO_SECONDS_DECIMAL_PLACE)
      end

      def have_timeout?(message)
        return true if message["timeout"]
        return false unless message["body"].is_a?(Hash)
        not message["body"]["timeout"].nil?
      end
    end
  end
end
