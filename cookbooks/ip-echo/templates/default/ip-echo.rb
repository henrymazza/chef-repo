#!/usr/bin/env ruby

require 'socket'

server = TCPServer.new 3038

Signal.trap("INT") do
  puts "\nTerminating..."
  exit
end

loop do
  client = server.accept    # Wait for a client to connect
  client.puts client.peeraddr[-1]
  client.close
end
