require 'sinatra'
require 'sinatra/activerecord'
require 'sqlite3'
require './models/User.rb'
require './models/Option.rb'
require 'json'
require 'redis'

get '/' do
  content_type :json
  #if no session active:
  {"message" => "Hello World!"}.to_json
end

get '/user' do
  User.last.options.first.json_object                               #will fine tune when doing authentication
end

post '/user' do
  params_json = JSON.parse(request.body.read)
  username = params_json["username"]
  password = params_json["password"]
  options_attributes = params_json.select { |k, v| k != "username" && k != "password" }.to_s
  User.create(username: username, password: password, options_attributes: [ { json_object: options_attributes }]) #will fine tune when doing authentication
end

put '/user' do
  params_json = JSON.parse(request.body.read)
  user_options = eval(User.last.options.first.json_object)
  params_json.each_key { |k| user_options[k] = params_json[k] }
  User.last.options.first.update(json_object: user_options.to_s)     #will fine tune when doing authentication
end

delete '/user' do
  User.last.destroy                                                   #will fine tune when doing authentication
end

post '/auth' do
  #generates and sets session token
end

delete '/auth' do
  #destroys session token
end
