require File.dirname(__FILE__) + '/../spec_helper'

describe "A message with the 'remove' keyword" do
  before(:each) do
    #Set up 2 twitter names with a few feeds each
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
    @acct2 = TwitterUser.create(:username => 'anothertwitteracct')
    @acct2.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://foo.com/blog/rss.xml', :blog_url => 'http://foo.com/blog', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://somefeed.com/rss.xml', :blog_url => 'http://somefeed.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://someotherfeed.com/rss.xml', :blog_url => 'http://someotherfeed.com/rss.xml', :max_days_before_nagging => 7)
  end
  
  describe "and the 'all' keyword" do
    before(:each) do
      @message = 'remove all'
      @tweet = mock('Pack', :text => @message, :from_user => @acct1.username)
    end
    
    it "should remove all messages for the requesting twitter name" do
      user_id = @acct1.id
      MessageProcessor.process_incoming_message(@tweet)
      Feed.find_all_by_twitter_user_id(user_id).should be_empty
    end
    
    it "should remove the user if the user exists" do
      username = @acct1.username
      @tweet = mock('Pack', :text => @message, :from_user => username)
      MessageProcessor.process_incoming_message(@tweet)
      TwitterUser.find_all_by_username(username).should be_empty
    end
    
    it "should add a message to the outbound queue" do
      username = @acct1.username
      @tweet = mock('Pack', :text => @message, :from_user => username)
      DelayedJob.count.should == 0
      MessageProcessor.process_incoming_message(@tweet)
      DelayedJob.count.should == 1
    end
  end
  
  describe "and a well-formed URL" do

    it "should delete any feeds for that user that are an exact match on the feed ID" do
      message = "remove http://foo.com/rss.xml"
      @acct1.feeds.size.should == 1
      @tweet = mock('Pack', :text => message, :from_user => @acct1.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct1.feeds.size.should == 0
    end
    
    it "should not delete any feeds for other users that match the feed URL" do
      message = "remove http://foo.com/rss.xml"
      @acct2.feeds.size.should == 4
      @tweet = mock('Pack', :text => message, :from_user => @acct1.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct2.feeds.size.should == 4
    end
    
    it "should add a message to the outbound queue" do
      username = @acct1.username
      @tweet = mock('Pack', :text => "remove http://foo.com/rss.xml", :from_user => username)
      DelayedJob.count.should == 0
      MessageProcessor.process_incoming_message(@tweet)
      DelayedJob.count.should == 1
    
    end
    
  end
  
  describe "and a valid URL but missing the http prefix" do
    it "should delete any feeds for that user that are an exact match on the feed ID" do
      message = "remove foo.com/rss.xml"
      @acct1.feeds.size.should == 1
      @tweet = mock('Pack', :text => message, :from_user => @acct1.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct1.feeds.size.should == 0
    end
    
    it "should not delete any feeds for other users that match the feed URL" do
      message = "remove foo.com/rss.xml"
      @acct2.feeds.size.should == 4
      @tweet = mock('Pack', :text => message, :from_user => @acct1.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct2.feeds.size.should == 4
    end
    
    it "should add a message to the outbound queue" do
      username = @acct1.username
      @tweet = mock('Pack', :text => "remove foo.com/rss.xml", :from_user => username)
      DelayedJob.count.should == 0
      MessageProcessor.process_incoming_message(@tweet)
      DelayedJob.count.should == 1
    end
  end
  
  describe "and a URL that doesn't match any of the feeds for that user" do
    it "should add a message to the outbound queue" do
      username = @acct1.username
      @tweet = mock('Pack', :text => "remove notafeed.com/rss.xml", :from_user => username)
      DelayedJob.count.should == 0
      MessageProcessor.process_incoming_message(@tweet)
      DelayedJob.count.should == 1
    end
    
  end
  
  describe "and a URL that matches the blog URL" do

    it "should delete the matching feed" do
      @acct2.feeds.size.should == 4
      @tweet = mock("Pack", :text => "remove foo.com", :from_user => @acct2.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct2.feeds.size.should == 3
    end
    
    it "should not delete any non-matching feeds" do
      @acct2.feeds.size.should == 4
      @tweet = mock("Pack", :text => "remove nomatch.com", :from_user => @acct2.username)
      MessageProcessor.process_incoming_message(@tweet)
      @acct2.feeds.size.should == 4
    end
    
    it "should add a message to the outbound queue" do
      DelayedJob.count.should == 0
      @tweet = mock("Pack", :text => "remove nomatch.com", :from_user => @acct2.username)
      MessageProcessor.process_incoming_message(@tweet)
      DelayedJob.count.should == 1
    end
  end
end

describe "A message with the 'all' keyword but not the 'remove' keyword" do
  it "should add an error message to the outbound queue" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "all", :from_user => "@anyuser")
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
  end
end

describe "A message without any keywords but with a new feed url for that user" do
  before(:each) do
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
  end
  
  it "should add the feed" do
    @acct1.feeds.size.should == 1
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => @acct1.username)
    MessageProcessor.process_incoming_message(@tweet)
    @acct1.feeds.size.should == 2
    @acct1.feeds.last.title.should == "Life as a Coder"
  end
  
  it "should send a message" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => @acct1.username)
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
  end
end

describe "A message without any keywords but with a new blog url for that user" do
  before(:each) do
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
  end
  
  it "should add the feed" do
    @acct1.feeds.size.should == 1
    @tweet = mock("Pack", :text => "http://lifeasacoder.com", :from_user => @acct1.username)
    MessageProcessor.process_incoming_message(@tweet)
    @acct1.feeds.size.should == 2
    @acct1.feeds.last.title.should == "Life as a Coder"
  end
  
  it "should send a message" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "http://lifeasacoder.com", :from_user => @acct1.username)
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
  end
end


describe "A message without any keywords but with a new feed url for an unknown user" do
  before(:each) do
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
  end
  
  it "should create the user" do
    TwitterUser.count.should == 1
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => "newuser")
    MessageProcessor.process_incoming_message(@tweet)
    TwitterUser.count.should == 2
  end
    
  it "should add the feed" do
    Feed.count.should == 1
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => "newuser")
    MessageProcessor.process_incoming_message(@tweet)
    Feed.count.should == 2
    Feed.last.twitter_user.username.should == "newuser"
    Feed.last.title.should == "Life as a Coder"
  end
  
  it "should send a message" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => "newuser")
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
  end
end


describe "A message without any keywords but with a url that is already present for that user" do
  before(:each) do
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://feeds.feedburner.com/lifeasacoder', :blog_url => 'http://lifeasacoder.com', :max_days_before_nagging => 7)
  end
  
  it "should tell the user the feed is already being tracked" do
    DelayedJob.count.should == 0
    @acct1.feeds.size.should == 1
    @tweet = mock("Pack", :text => "http://feeds.feedburner.com/lifeasacoder", :from_user => @acct1.username)
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
    @acct1.feeds.size.should == 1
  end  
end

describe "A message with a message I don't understand!" do
  it "should do nothing!" do
  
  end
end

describe "A message with the keyword 'list'" do
  before(:each) do
    #Set up 2 twitter names with a few feeds each
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
    @acct2 = TwitterUser.create(:username => 'anothertwitteracct')
    @acct2.feeds.create(:feed_url => 'http://foo.com/rss.xml', :blog_url => 'http://foo.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://foo.com/blog/rss.xml', :blog_url => 'http://foo.com/blog', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://somefeed.com/rss.xml', :blog_url => 'http://somefeed.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://someotherfeed.com/rss.xml', :blog_url => 'http://someotherfeed.com/rss.xml', :max_days_before_nagging => 7)
  end

  
  it "should add an outbound message to the queue for each followed feed for that user, plus 1 summary message" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "list", :from_user => @acct2.username)
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 5
  end
end

describe "A message with the keyword 'help'" do
  it "should add an outbound help message to the user" do
    DelayedJob.count.should == 0
    @tweet = mock("Pack", :text => "help", :from_user => 'username')
    MessageProcessor.process_incoming_message(@tweet)
    DelayedJob.count.should == 1
  end
end

