namespace :blognag do
  task (:get_messages => :environment) do
    MessageProcessor.sweep_for_incoming_tweets
  end

  task (:clear_last_tweet_id => :environment) do
    CurrentMessage.delete_all
  end
  
  task (:sweep_feeds => :environment) do
    Feed.schedule_update_checks
  end

end
