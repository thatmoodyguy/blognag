module MessageProcessor
  
  def self.process_incoming_message(message, sender_username)
    #determine the kind of message this is!
    user = TwitterUser.find_by_username(sender_username) rescue nil
    msgs = message.downcase.split
    if msgs.include?("remove")
      if message.include?("all")
        remove_all(user)
      else
        send_bad_message_response unless remove(msgs, user)
      end
    end
  end
  
protected
  def self.remove_all(user)
    user.destroy unless user.nil?
  end
  
  def self.remove(msgs, user)
    msgs.delete("remove")
    msgs.each do |msg|
      # Figure out if this is really a URL or not
      Feed.delete_for(msg, user)
    end
    true
  end
  
  def send_bad_message_response
  end
  
end