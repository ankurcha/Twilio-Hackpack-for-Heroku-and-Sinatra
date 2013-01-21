require 'sinatra'
require "sinatra/twilio"

require 'logger'

# Home page and reference
get '/' do
  @title = "Home"
  erb :home
end

caller_pins = { '+12139095359' => '161286', '+12069193585' => '170689', '+14242658703' => '16121986'}
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

# Generic voice call handler, receives calls and replies with pin if one of the owners
# else redirects to authenticate flow
respond "/call" do
  logger.debug "Call received from #{params[:From]} with parameters #{params} for pin query"

  addSay "Welcome caller."
  
  if caller_pins.has_key? params[:From]
    # An authorized user is calling reply with the pins
    logger.info "Pin given to #{params[:From]}"
    addSay "Your pin is #{caller_pins[params[:From]]}"    
  else
    addRedirect "/authenticate"
  end
end

# SMS Request URL
respond '/sms/?' do
  response = Twilio::TwiML::Response.new do |r|
    if caller_pins.has_key? params[:From]
      # An authorized user is calling reply with the pins
      logger.info "Pin given to #{params[:From]}"
      r.Sms "Your pin is #{caller_pins[params[:From]]}"    
    else
      r.Sms 'You are not authorized to use this service.'
    end    
  end
  response.text
end
# Sends back play message
respond "/allowed_call" do  
  addPlay "http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/9.wav"
end

# performs authentication by asking user to key in the pin,
# it then looks up the pin (if params[:Digits] is set) and redirects to /allowed_call if successful
respond "/authenticate" do

  if caller_pins.has_value? params[:Digits]
    logger.info "[ACCESS GRANTED] to caller #{params[:From]}"    
    addRedirect "/allowed_call"
  else
    gather = Twilio::Gather.new(:action => "/authenticate")
    gather.addSay "Please enter your PIN followed by the pound key:"
    append gather

    addSay "You did not enter a pin. Good bye!"
    addHangup
  end
end