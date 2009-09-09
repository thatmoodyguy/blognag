class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.integer     :twitter_user_id
      t.string      :feed_url
      t.string      :supplied_url
      t.datetime    :last_checked_at
      t.datetime    :last_posted_at
      t.integer     :max_days_before_nagging
      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
