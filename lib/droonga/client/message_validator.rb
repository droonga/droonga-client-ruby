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
    class MessageValidator
      class MissingId < ArgumentError
      end

      class MissingDataset < ArgumentError
      end

      class InvalidDate < ArgumentError
      end

      def initialize(options={})
        @options = options
      end

      def validate(message)
        validate_id(message)
        validate_dataset(message)
        validate_date(message)
      end

      private
      def validate_id(message)
        unless message["id"]
          raise MissingId.new(message["id"])
        end
      end

      def validate_dataset(message)
        unless message["dataset"]
          raise MissingDataset.new(message["dataset"])
        end
      end

      def validate_date(message)
        Time.parse(message["date"])
      rescue ArgumentError => error
        raise InvalidDate.new(message["date"])
      end
    end
  end
end
