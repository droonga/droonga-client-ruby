# -*- coding: utf-8 -*-
#
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

require "droonga/client/version"
require "droonga/client/error"
require "droonga/client/connection/http"
require "droonga/client/connection/droonga-protocol"
require "droonga/client/rate-limiter"
require "droonga/client/message_completer"
require "droonga/client/message_validator"

module Droonga
  class Client
    DEFAULT_PROTOCOL = :droonga
    DEFAULT_HOST = Socket.gethostname
    DEFAULT_HOST.force_encoding("US-ASCII") if DEFAULT_HOST.ascii_only?
    DEFAULT_PORT = 10031
    DEFAULT_TAG  = "droonga"
    DEFAULT_DATASET = "Default"
    DEFAULT_TARGET_ROLE = "any"
    DEFAULT_TIMEOUT_SECONDS = 3

    attr_writer :on_error
    attr_reader :protocol

    class ConnectionError < StandardError
      def initialize(error)
        super(error.inspect)
      end
    end

    class << self
      # Opens a new connection and yields a {Client} object to use the
      # connection. The client is closed after the given block is
      # finished.
      #
      # @param (see #initialize)
      # @option (see #initialize)
      #
      # @yield [client] Gives the opened client. It is alive while yielding.
      # @yieldparam client [Client] The opened client.
      #
      # @return The return value from the given block.
      def open(options={})
        client = new(options)
        begin
          yield(client)
        ensure
          client.close
        end
      end
    end

    # Creates a new Droonga Engine client.
    #
    # @param options [Hash] Options to connect Droonga Engine.
    # @option options [String] :tag ("droonga") The tag of the request message.
    # @option options [String] :host ("127.0.0.1")
    #   The host name or IP address of the Droonga Engine to be connected.
    # @option options [Integer] :port (24224)
    #   The port number of the Droonga Engine to be connected.
    # @option options [String] :receiver_host (Socket.gethostname)
    #   The host name or IP address to receive response from the Droonga Engine.
    # @option options [Integer] :receiver_port (0)
    #   The port number to receive response from the Droonga Engine.
    # @option options [Integer] :timeout (5)
    #   The timeout value for connecting to, writing to and reading
    #   from Droonga Engine.
    # @option options [Boolean] :completion (true)
    #   Do or do not complete required fields of input messages.
    # @option options [Boolean] :validation (true)
    #   Do or do not validate input messages.
    def initialize(options={})
      @protocol = options[:protocol] || DEFAULT_PROTOCOL
      @connection = create_connection(options)
      @connection.on_error = lambda do |error|
        on_error(ConnectionError.new(error))
      end

      @completion = options[:completion] != false
      @validation = options[:validation] != false

      @completer = MessageCompleter.new(:default_dataset => options[:default_dataset],
                                        :default_timeout => options[:default_timeout],
                                        :default_target_role => options[:default_target_role])
      @validator = MessageValidator.new
    end

    def send(message, options={}, &block)
      message = do_completion(message, options)
      do_validation(message, options)
      @connection.send(message, options, &block)
    end

    def request(message, options={}, &block)
      message = do_completion(message, options)
      do_validation(message, options)
      @connection.request(message, options, &block)
    end

    def subscribe(message, options={}, &block)
      message = do_completion(message, options)
      do_validation(message, options)
      @connection.subscribe(message, options, &block)
    end

    # Close the connection used by the client. You can't send any
    # request anymore.
    #
    # @return [void]
    def close
      @connection.close
    end

    def complete(message)
      case @protocol
      when :http
        http_request = @connection.build_request(message)
        http_headers = {}
        http_request.canonical_each do |name, value|
          http_headers[name] = value
        end
        {
          "method"  => http_request.method,
          "path"    => http_request.path,
          "headers" => http_headers,
          "body"    => http_request.body,
        }
      when :droonga
        do_completion(message, :completion => true)
      else
        nil
      end
    end

    private
    def create_connection(options)
      case @protocol
      when :http
        Connection::HTTP.new(options)
      when :droonga
        Connection::DroongaProtocol.new(options)
      end
    end

    def do_completion(message, options={})
      if options[:completion].nil?
        return message unless @completion
      else
        return message if options[:completion] == false
      end
      @completer.complete(message)
    end

    def do_validation(message, options={})
      if options[:validation].nil?
        return unless @validation
      else
        return if options[:validation] == false
      end
      @validator.validate(message)
    end

    def on_error(error)
      @on_error.call(error) if @on_error
    end
  end
end
