class FixIntegerSizeForCurrentMessages < ActiveRecord::Migration
  def self.up
    remove_column :current_messages, :last_message_id
    add_column    :current_messages, :last_message_id, :integer, :limit => 8
  end

  def self.down
    remove_column :current_messages, :last_message_id
    add_column   :current_messages, :last_message_id, :integer
  end
end
