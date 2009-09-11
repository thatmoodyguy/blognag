class MessageProcessor
  
  def self.process_incoming_message(tweet)
    process(tweet.text, tweet.from_user)
  end
  
  def self.queue_outgoing_message(user, message)
    user = user.username if user.respond_to?(:username)
    user = "@#{user}" unless user[0,1] == "@"
    msg = "#{user} #{message}"
    MessageProcessor.send_later(:send_outgoing_message, msg)
  end
  
protected
  def self.send_outgoing_message(message)
    return if RAILS_ENV == 'test'     # so I don't spam Twitter with my specs!!!!
    httpauth = Twitter::HTTPAuth.new('blognag', 'maleldil')
    client = Twitter::Base.new(httpauth)
    client.update(message)
  end

  def self.process(message, sender_username)
    #determine the kind of message this is!
    RAILS_DEFAULT_LOGGER.info "Processing message from #{sender_username}: #{message}"
    user = TwitterUser.find_by_username(sender_username) rescue nil
    msgs = message.downcase.split
    msgs.delete "@blognag"
    case msgs.first
    when "remove" 
      if message.include?("all")
        remove_all(user)
      else
        send_bad_message_response(sender_username) unless remove(msgs, user)
      end
    when "list"
      send_list_messages(sender_username)
    when "help"
      send_help_message(sender_username)
    else
      if Feed.is_valid_url?(msgs.first)  
        num_days = msgs[1].to_i rescue 7
        user = TwitterUser.create(:username => sender_username) if user.nil?
        Feed.create_for_url(msgs.first, user, num_days)
      else
        send_bad_message_response(sender_username)
      end
    end
  end
  
  def self.remove_all(user)
    return if user.nil?
    user.destroy
    queue_outgoing_message user, "Your feeds have been removed. Thanks for using BlogNag!"
  end
  
  def self.remove(msgs, user)
    msgs.delete("remove")
    msgs.each do |msg|
      # Figure out if this is really a URL or not
      Feed.delete_for(msg, user)
      queue_outgoing_message user, "Your feed has been removed. Thanks for using BlogNag!"      
    end
    true
  end
  
  def self.send_bad_message_response(username)
    queue_outgoing_message username, "Sorry, I couldn't understand your request. Tweet '@blognag help' for instructions!"
  end
  
  def self.send_list_messages(username)
    user = TwitterUser.find_by_username(username) rescue nil
    if user.nil? || user.feeds.size == 0
      queue_outgoing_message username, "You aren't tracking any blogs yet. To be reminded to post to a blog, tweet '@blognag http://myblog.com'."       
    else
      queue_outgoing_message username, "You are tracking #{pluralize(user.feeds.size, "blog")}."
      user.feeds.each do |feed| 
        queue_outgoing_message username, "#{feed.blog_url} - after #{pluralize(feed.max_days_before_nagging, "day")}"               
      end
    end
  end
  
  def self.send_help_message(username)
    queue_outgoing_message(username, "To be reminded to post to a blog, tweet '@blognag http://myblog.com'. More commands at http://blognag.mentalvelocity.com.")
  end
  
  def self.pluralize(count, singular, plural = nil)
    "#{count || 0} " + ((count == 1 || count == '1') ? singular : (plural || singular.pluralize))
  end
  
  
end