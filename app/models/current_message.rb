class CurrentMessage < ActiveRecord::Base
  validates_presence_of :last_message_id
  
  def self.get_last_id
    get_or_create_current_message.last_message_id
  end
  
  def self.update_last_id(new_id)
    msg = CurrentMessage.find :first
    if msg.nil?
      CurrentMessage.create :last_message_id, new_id
    else
      msg.update_attribute :last_message_id, new_id
    end
  end
  
protected
  def self.get_or_create_current_message
    CurrentMessage.first || CurrentMessage.create(:last_message_id => 0)
  end
  
end
