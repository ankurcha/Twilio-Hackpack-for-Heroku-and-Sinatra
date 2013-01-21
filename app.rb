require 'sinatra'
require "sinatra/twilio"

require 'logger'

# A hack around multiple routes in Sinatra
def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

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
get_or_post "/call" do
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
get_or_post '/sms' do
  response = Twilio::TwiML::Response.new
  if caller_pins.has_key? params[:From]
    case params[:Body]
    when 'pin'
      # An authorized user is calling reply with the pins
      logger.info "Pin given to #{params[:From]}"
      response.Sms "Your pin is #{caller_pins[params[:From]]}"    
    when 'new'
      response.Sms 'Create a new 24 hr token is not yet implemented.'
    else
      response.Sms 'Unknown request'
    end
  else
    response.Sms 'You are not authorized to make this request.'
  end
  response.text
end
# Sends back play message
get_or_post "/allowed_call" do  
  addPlay "http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/9.wav"
end

# performs authentication by asking user to key in the pin,
# it then looks up the pin (if params[:Digits] is set) and redirects to /allowed_call if successful
get_or_post "/authenticate" do

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