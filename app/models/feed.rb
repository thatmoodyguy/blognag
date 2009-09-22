require 'nokogiri'
require 'open-uri'
require 'feedzirra'

class Feed < ActiveRecord::Base
  belongs_to :twitter_user
  validates_presence_of :feed_url, :blog_url, :max_days_before_nagging
  
  def self.schedule_update_checks
    Feed.all.each do |feed|
      Feed.send_later :check_feed_for_updates, feed.id
    end
  end
  
  def self.check_feed_for_updates(feed_id)
    feed = Feed.find(feed_id) rescue nil
    feed.check_for_updates unless feed.nil?
  end
  
  def check_for_updates
    return if last_checked_at && last_checked_at.beginning_of_day >= Time.zone.now.beginning_of_day
    last_date = latest_post_date_from_feed
    unless last_date.nil?
      update_attributes :last_posted_at => last_date, :last_checked_at => Time.zone.now
      if post_days_ago > max_days_before_nagging
        send_nag_message(post_days_ago)
      end
    end
  end
  
  def post_days_ago
    return 0 if last_checked_at.nil?
    ((Time.zone.now.beginning_of_day - last_posted_at.beginning_of_day)/60/60/24).to_i
  end
  
  def self.is_valid_url?(msg)
    prepend_http_if_missing(msg) =~ REGEXP
  end
  
  def self.create_for_url(url, user, number_of_days)
    number_of_days = 7 if number_of_days < 1
    number_of_days = 99 if number_of_days > 99
    if feed_exists_for_user?(url, user)
      MessageProcessor.queue_outgoing_message user, "You are already tracking that blog! Tweet '@blognag list' to view all your tracked blogs."      
      return
    end
    feed = get_feed_object(url)
    unless feed.nil?
      user.feeds.create(:feed_url => feed.feed_url, :blog_url => feed.url, :title => feed.title, :max_days_before_nagging => number_of_days)
      MessageProcessor.queue_outgoing_message user, "Your blog has been added. We'll send you a quasi-friendly reminder when you haven't posted to it in #{number_of_days} days."
    else
      feed_url = extract_feed_url_from_html(url)
      feed = get_feed_object(feed_url)
      unless feed.nil?
        user.feeds.create(:feed_url => feed.feed_url, :blog_url => feed.url, :title => feed.title, :max_days_before_nagging => number_of_days)
        MessageProcessor.queue_outgoing_message user, "Your blog has been added. We'll send you a quasi-friendly reminder when you haven't posted to it in #{number_of_days} days."
      else
        #feed isn't good - complain!
      end
    end
  end
  
  def self.find_matches(url, user)
    url = prepend_http_if_missing(url)
    matches = self.find_by_feed_url(url)
    matches << self.find_by_blog_url(url)
    
  end
  
  def self.delete_for(url, user)
    url = prepend_http_if_missing(url)
    Feed.delete_all(['twitter_user_id = ? AND (feed_url = ? or blog_url = ?)', user.id, url, url]) #deletes any feed matches
    user.destroy if user.feeds.size == 0
  end
  
protected

  
  def send_nag_message(days_ago)
    message = "A friendly reminder from @blognag: You haven't posted to your blog in #{pluralize(days_ago, "day")}. Write something!"
    MessageProcessor.queue_outgoing_message(twitter_user.username, message)
  end

  def latest_post_date_from_feed
    feed = Feed.get_feed_object(feed_url) rescue nil
    if feed.nil?
      nil
    else
      feed.entries.first.published rescue nil
    end
  end

  def self.extract_feed_url_from_html(url)
    url = prepend_http_if_missing(url)
    doc = Nokogiri::HTML(open(url))
    return nil if doc.nil?
    doc.search('head link[type="application/rss+xml"]').first.attributes["href"].to_s rescue nil
  end

  def self.feed_exists_for_user?(url, user)
    url = prepend_http_if_missing(url)
    self.count(:conditions => ['twitter_user_id = ? AND (feed_url = ? OR blog_url = ?)', user.id, url, url]) > 0
  end

  def self.get_feed_object(url)
    return nil if url.nil? || url.blank?
    url = prepend_http_if_missing(url)
    feed = Feedzirra::Feed.fetch_and_parse(url) rescue nil
    feed.respond_to?(:blog_url) ? nil : feed   
  end

  def self.prepend_http_if_missing(url)
    url[0,4] == "http" ? url : "http://#{url}"
  end
  
  def self.get_domain_from(url)
    url = prepend_http_if_missing(url)
    URI.parse(url).host rescue ''
  end

  def self.domain_root?(url)
    url = prepend_http_if_missing(url)
    path = URI.parse(url).path
    path.blank? || path == "/"
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
  
  def pluralize(count, singular, plural = nil)
    Feed.pluralize(count, singular, plural)
  end
  
  def self.pluralize(count, singular, plural = nil)
    "#{count || 0} " + ((count == 1 || count == '1') ? singular : (plural || singular.pluralize))
  end

end
