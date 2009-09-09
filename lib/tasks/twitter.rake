namespace :blognag do
  task (:get_messages => :environment) do
    last_id = CurrentMessage.get_last_id
    if last_id == 0
      tweets = Twitter::Search.new.to('blognag').per_page(100).fetch()
    else
      tweets = Twitter::Search.new.to('blognag').since(last_id).per_page(100).fetch()
    end
    unless tweets.empty?
      tweets.each do |tweet|
        MessageProcessor.process_incoming_message(tweet.text, from_user)
      end
      CurrentMessage.update_last_id(tweets.first.id)
    end
  end

end