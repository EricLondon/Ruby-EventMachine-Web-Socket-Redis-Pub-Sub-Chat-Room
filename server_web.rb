#!/usr/bin/env ruby

require 'sinatra'

set :server, :thin

get '/' do
  erb :chat_room
end
