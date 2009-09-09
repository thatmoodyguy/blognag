class CurrentMessage < ActiveRecord::Base
  validates_presence_of :last_message_id
  
  def self.get_last_id
    current = CurrentMessage.first rescue nil
    if current.nil?
      CurrentMessage.create(:last_message_id = 0)
      0
    else
      current.last_message_id
    end
    
  end
  
end
