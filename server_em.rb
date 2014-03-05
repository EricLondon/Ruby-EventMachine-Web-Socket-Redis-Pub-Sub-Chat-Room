#!/usr/bin/env ruby

require 'em-websocket'
require 'em-hiredis'
require 'json'
require 'logger'

module ChatServer
  extend self
  DEFAULT_CHAT_ROOM = 'default'
  DEFAULT_USER_NAME = 'anonymous'
  DEFAULT_MESSAGE = ':)'
  VALID_MESSAGE_KEYS = ['user_name', 'chat_room', 'message']

  def chat_room_name(data)
    return DEFAULT_CHAT_ROOM if data.nil? || !data.respond_to?(:gsub)
    chat_room_name = data.gsub(/\W/,'')
    return DEFAULT_CHAT_ROOM if chat_room_name.nil? || chat_room_name.empty?
    chat_room_name
  end

  def user_name(data)
    return DEFAULT_USER_NAME if data.nil? || !data.respond_to?(:gsub)
    user_name = data.gsub(/[^\w\ ]/, '')
    return DEFAULT_USER_NAME if user_name.nil? || user_name.empty?
    user_name
  end

  def clean_message(message)
    return DEFAULT_MESSAGE if message.nil? || !message.respond_to?(:gsub)
    return message.gsub(/<(?:.|\n)*?>/, '')
  end

  def message_string_to_object(message_string)

    begin
      data = JSON.parse message_string
    rescue => e
      data = {}
    end

    # remove invalid keys
    data.delete_if {|key,value| !VALID_MESSAGE_KEYS.include?(key) }

    # clean data
    data['message'] = clean_message data['message']
    data['chat_room'] = chat_room_name data['chat_room']
    data['user_name'] = user_name data['user_name']

    data

  end

end

EM.run do

  @log = Logger.new(STDOUT)

  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|

    # event: web socket open
    ws.onopen do |handshake|

      chat_room_name = ChatServer.chat_room_name handshake.path

      # log
      @log.info "WebSocket connection opened; chat room: #{chat_room_name}"

      # connect to Redis and subscribe
      @redis = EM::Hiredis.connect
      pubsub = @redis.pubsub
      pubsub.subscribe chat_room_name
      pubsub.on(:message) do |channel, message|

        # log
        @log.debug "redis pubsub.on(:message); channel: #{channel}; message: #{message}"

        ws.send ChatServer.message_string_to_object(message).to_json

      end

    end

    # event: web socket close
    ws.onclose do

      # log
      @log.info "WebSocket connection closed"

    end

    # event: web socket received message
    ws.onmessage do |message|

      # log
      @log.debug "ws.onmessage; message: #{message}"

      begin

        # parse/clean json message
        data = ChatServer.message_string_to_object message

        # publish to redis pubsub
        @redis.publish data['chat_room'], data.to_json

      rescue => e
        @log.error e
      end

    end

  end

end