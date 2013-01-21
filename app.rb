require 'sinatra'
require "sinatra/twilio"

# Home page and reference
get '/' do
  @title = "Home"
  erb :home
end

caller_pins = Hash.new({ '+12139095359' => '161286', '+12069193585' => '170689' })

respond "/call" do
  addSay "Welcome caller."

  if caller_pins.has_key? params[:From]
    # An authorized user is calling reply with the pins
    addSay "Your pin is #{caller_pins[params[:From]]}"    
  else
    addRedirect "/authenticate"
  end
end

respond "/allowed_call" do
  addPlay "http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/9.wav"
end

respond "/authenticate" do
  if caller_pins.has_value? params[:Digits]
    addRedirect "/allowed_call"
  else
    gather = Twilio::Gather.new(:action => "/authenticate")
    gather.addSay "Please enter your PIN followed by the pound key:"
    append gather

    addSay "You did not enter a pin. Good bye!"
    addHangup
  end
end