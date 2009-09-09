class TwitterUser < ActiveRecord::Base
  has_many :feeds, :dependent => :destroy
  validates_presence_of :username
  
end
