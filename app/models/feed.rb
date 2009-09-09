class Feed < ActiveRecord::Base
  belongs_to :twitter_user
  validates_presence_of :feed_url, :supplied_url, :max_days_before_nagging
  
  def self.is_valid_url?(msg)
    prepend_http_if_missing(msg) =~ REGEXP
  end
  
  def self.create_for_url(url, user)

  end
  
  def self.delete_for(url, user)
    url = prepend_http_if_missing(url)
    Feed.delete_all(['twitter_user_id = ? AND feed_url = ?', user.id, url])
  end
  
protected

  def self.prepend_http_if_missing(url)
    url[0,4] == "http" ? url : "http://#{url}"
  end

IPv4_PART = /\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/ # 0-255
  
REGEXP = %r{
  \A
  https?:// # http:// or https://
  ([^\s:@]+:[^\s:@]*@)? # optional username:pw@
  ( (xn--)?[^\W_]+([-.][^\W_]+)*\.[a-z]{2,6}\.? | # domain (including Punycode/IDN)...
  #{IPv4_PART}(\.#{IPv4_PART}){3} ) # or IPv4
  (:\d{1,5})? # optional port
  ([/?]\S*)? # optional /whatever or ?whatever
  \Z
  }iux

end
