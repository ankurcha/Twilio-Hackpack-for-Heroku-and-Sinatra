require 'sinatra'
require "sinatra/twilio"

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

# Voice Request URL
# get '/voice/?' do
#   response = Twilio::TwiML::Response.new do |r|
#     r.Gather :timeout => 10, :method =>'POST', :action => 'http://immense-headland-2964.herokuapp.com/voice' do |g|
#       g.Say 'Please enter your passcode', :voice => 'woman'
#     end        
#   end
#   response.text
# end


# post '/voice/?' do
#   response = Twilio::TwiML::Response.new do |r|
#     r.Play 'http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/9.wav', :loop => 5
#   end
#   response.text
# end


callers = %w[+15551234567]
pin     = "1234"

respond "/call" do
  addSay "Welcome caller."

  if callers.include? params[:From]
    addRedirect "/allowed_call"
  else
    addRedirect "/disallowed_call"
  end
end

respond "/allowed_call" do
  addPlay "/latest_message.mp3"
end

respond "/disallowed_call" do
  gather = Twilio::Gather.new(:action => "/authenticate")
  gather.addSay "Please enter your PIN now:"
  append gather

  addSay "You did not enter a pin. Good bye!"
  addHangup
end

respond "/authenticate" do
  if params[:Digits] == pin
    addRedirect "/allowed_call"
  else
    addRedirect "/disallowed_call"
  end
end

get "/latest_message.mp3" do
  # Assuming we have an ORM...
  send_file Message.last.path, :stream => true
end