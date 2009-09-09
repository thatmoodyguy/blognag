class CreateCurrentMessages < ActiveRecord::Migration
  def self.up
    create_table :current_messages do |t|
      t.integer :last_message_id 
      t.timestamps
    end
  end

  def self.down
    drop_table :current_messages
  end
end
