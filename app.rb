require 'sinatra'
require 'sinatra/activerecord'
require 'sqlite3'
require './models/User.rb'
require './models/Option.rb'
require 'json'
require 'redis'
require 'bcrypt'
require 'securerandom'

get '/' do
  content_type :json
  greeting_hash = {"message" => "Hello World!"}
  redis = Redis.new
  user_id = redis.get(request.cookies["session_token"])
  if user_id 
    username_hash = Hash.new
    username_hash["username"] = User.find(user_id).username
    if User.find(user_id).options.count > 0
      stored_options = eval(User.find(user_id).options.first.json_object)
      greeting_hash.merge(stored_options).merge(username_hash).to_json
    elsif User.find(user_id).options.count == 0
      greeting_hash.merge(username_hash).to_json
    end
  else
    greeting_hash.to_json
  end
end

get '/user' do
  content_type :json
  redis = Redis.new
  user_id = redis.get(request.cookies["session_token"])
  if user_id
    eval(User.find(user_id).options.first.json_object).to_json
  end
end

post '/user' do
  params_json = JSON.parse(request.body.read)
  username = params_json["username"]
  password = params_json["password"]
  options_attributes = params_json.select { |k, v| k != "username" && k != "password" }.to_s
  User.create(username: username, password: password, options_attributes: [ { json_object: options_attributes }])
end

put '/user' do                                            # allows altering and adding information only (no delete)
  redis = Redis.new
  user_id = redis.get(request.cookies["session_token"])
  if user_id
    user_options = eval(User.find(user_id).options.first.json_object)
    params_json = JSON.parse(request.body.read)
    params_json.each_key { |k| user_options[k] = params_json[k] }
    User.find(user_id).options.first.update(json_object: user_options.to_s)
  end
end

delete '/user' do
  redis = Redis.new
  session_token = request.cookies["session_token"]
  user_id = redis.get(session_token)
  if user_id
    User.find(user_id).destroy
    redis.del(session_token)                              # invalidates session token too
  end
end

post '/auth' do
  params_json = JSON.parse(request.body.read)
  username = params_json["username"]
  password = params_json["password"]
  user = User.authenticate(username, password)
  if user
    user_id = user.id
    session_token = SecureRandom.urlsafe_base64
    redis = Redis.new
    redis.set(session_token, user_id)
    redis.expire(session_token, 86400)
    response.set_cookie(:session_token, :value => session_token, :domain => "")
  end
end

delete '/auth' do
  session_token = request.cookies["session_token"]
  if session_token
    redis = Redis.new
    redis.del(session_token)
  end
end
