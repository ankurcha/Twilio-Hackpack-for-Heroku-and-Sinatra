require 'sinatra'
require 'twilio-ruby'
require "sinatra/twilio"
require 'supermodel'
require 'logger'


class DoorPin < SuperModel::Base; end

# Home page and reference
get '/' do
  @title = "Home"
  erb :home
end

DoorPin.new(:phone => '+12139095359', :pin => '161286', :owner => 'admin').save
DoorPin.new(:phone => '+12069193585', :pin => '170689', :owner => 'admin').save
DoorPin.new(:phone => '+14242658703', :pin => '16121986', :owner => 'admin').save

caller_pins = { '+12139095359' => '161286', '+12069193585' => '170689', '+14242658703' => '16121986'}
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

# Generic voice call handler, receives calls and replies with pin if one of the owners
# else redirects to authenticate flow
respond "/call" do
  logger.debug "Call received from #{params[:From]} with parameters #{params} for pin query"

  addSay "Welcome caller."
  door_pin = DoorPin.find_by_phone(params[:From])
  if door_pin
    # An authorized user is calling reply with the pins
    logger.info "Pin given to #{params[:From]}"
    addSay "Your pin is #{door_pin.pin}"    
  else
    addRedirect "/authenticate"
  end
end

# SMS Request URL
respond '/sms' do
  logger.debug "received sms with #{params}"  
  door_pin = DoorPin.find_by_phone(params[:From])
  if door_pin
    case params[:Body]
    when 'pin'
      # An authorized user is calling reply with the pins
      logger.info "Pin given to #{params[:From]}"
      addSms "Your pin is #{door_pin.pin}"    
    when 'new'
      new_pin = rand(999999).to_s.center(6, rand(9).to_s)
      DoorPin.new(:phone => params[:From], :pin => new_pin, :owner => params[:From]).save
      addSms 'New Pin created: #{new_pin}'
      # TODO: add TTL
    else
    addSms 'Unknown request'
    end
  else
    addSms 'You are not authorized to make this request.'
  end
end
# Sends back play message
respond "/allowed_call" do  
  addPlay "http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/9.wav"
end

# performs authentication by asking user to key in the pin,
# it then looks up the pin (if params[:Digits] is set) and redirects to /allowed_call if successful
respond "/authenticate" do

  door_pin = DoorPin.find_by_pin(params[:Digits])
  if door_pin
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