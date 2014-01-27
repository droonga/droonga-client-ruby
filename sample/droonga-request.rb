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

require "optparse"
require "json"

require "droonga/client"

options = {
  :host          => "localhost",
  :port          => 24224,
  :tag           => "droonga",
  :protocol      => :droonga,
  :timeout       => 1,
  :receiver_host => "localhost",
  :receiver_port => 0,
}

parser = OptionParser.new
parser.banner += " REQUEST_JSON_FILE"
parser.separator("")
parser.separator("Connect:")
parser.on("--host=HOST",
          "Host name to be connected.",
          "(#{options[:host]})") do |host|
  options[:host] = host
end
parser.on("--port=PORT", Integer,
          "Port number to be connected.",
          "(#{options[:port]})") do |port|
  options[:port] = port
end
parser.on("--tag=TAG",
          "Tag name to be used to communicate with Droonga system.",
          "(#{options[:tag]})") do |tag|
  options[:tag] = tag
end
available_protocols = [:droonga, :http]
parser.on("--protocol=PROTOCOL", available_protocols,
          "Protocol to be used to communicate with Droonga system.",
          "[#{available_protocols.join('|')}",
          "(#{options[:protocol]})") do |protocol|
  options[:protocol] = protocol
end
parser.separator("")
parser.separator("Timeout:")
parser.on("--timeout=TIMEOUT", Integer,
          "Timeout for operations.",
          "(#{options[:timeout]})") do |timeout|
  options[:timeout] = timeout
end
parser.separator("")
parser.separator("Droonga protocol:")
parser.on("--receiver-host=HOST",
          "Host name to be received a response from Droonga engine.",
          "(#{options[:receiver_host]})") do |host|
  options[:receiver_host] = host
end
parser.on("--receiver-port=PORT", Integer,
          "Port number to be received a response from Droonga engine.",
          "(#{options[:receiver_port]})") do |port|
  options[:receiver_port] = port
end
*rest = parser.parse!(ARGV)

if rest.size < 1
  puts("request JSON file is missing.")
  exit(false)
end

request_json_file = rest.first

client = Droonga::Client.new(options)
request = JSON.parse(File.read(request_json_file))
response = client.request(request)
begin
  puts(JSON.pretty_generate(response))
rescue
  p(response)
end
