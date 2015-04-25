class User < ActiveRecord::Base
  attr_accessor :password
  
  has_many :options, :dependent => :destroy

  accepts_nested_attributes_for :options

  before_save :encrypt_password

  def self.authenticate(username, password)
    user = User.find_by username: username
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    self.password_salt = BCrypt::Engine.generate_salt
    self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
  end
end
