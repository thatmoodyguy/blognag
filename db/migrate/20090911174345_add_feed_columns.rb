class AddFeedColumns < ActiveRecord::Migration
  def self.up
    add_column :feeds, :blog_url, :string
    add_column :feeds, :title, :string
    remove_column :feeds, :supplied_url
  end

  def self.down
    remove_column :feeds, :blog_url
    remove_column :feeds, :title
    add_column :feeds, :supplied_url, :string
  end
end

