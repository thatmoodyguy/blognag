namespace :blognag do
  task (:get_messages => :environment) do
    last_id = CurrentMessage.get_last_id
    if last_id == 0
      tweets = Twitter::Search.new.to('blognag').per_page(100)
    else
      tweets = Twitter::Search.new.to('blognag').since(last_id).per_page(100)
    end
    tweets.each do |tweet|
      tweet_object = Tweet.new(:text => tweet.text, :from_user => tweet.from_user)
      MessageProcessor.send_later(:process_incoming_message, tweet_object)
    end
    CurrentMessage.update_last_id(tweets.max_id)
  end

end
