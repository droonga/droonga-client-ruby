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

module Droonga
  class Client
    class RateLimiter
      NO_LIMIT = -1

      def initialize(client, messages_per_second)
        @client = client
        @messages_per_second = messages_per_second
      end

      def send(*args, &block)
        limit do
          @client.send(*args, &block)
        end
      end

      def method_missing(name, *args, &block)
        if @client.respond_to?(name)
          @client.__send__(name, *args, &block)
        else
          super
        end
      end

      private
      def limit
        return yield if @messages_per_second == NO_LIMIT

        if @current.to_i != Time.now.to_i
          reset_counter
        end

        @n_sent_messages_in_second += 1
        if @n_sent_messages_in_second > @messages_per_second
          sleep(Time.at(@current.to_i + 1) - @current)
          reset_counter
        end

        yield
      end

      def reset_counter
        @current = Time.now
        @n_sent_messages_in_second = 0
      end
    end
  end
end
