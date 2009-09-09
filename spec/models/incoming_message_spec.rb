require File.dirname(__FILE__) + '/../spec_helper'

describe "A message with the 'remove' keyword" do
  before(:each) do
    #Set up 2 twitter names with a few feeds each
    @acct1 = TwitterUser.create(:username => 'mytwitteracct')
    @acct1.feeds.create(:feed_url => 'http://foo.com/rss.xml', :supplied_url => 'foo.com', :max_days_before_nagging => 7)
    @acct2 = TwitterUser.create(:username => 'anothertwitteracct')
    @acct2.feeds.create(:feed_url => 'http://foo.com/rss.xml', :supplied_url => 'foo.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://somefeed.com/rss.xml', :supplied_url => 'http://somefeed.com', :max_days_before_nagging => 7)
    @acct2.feeds.create(:feed_url => 'http://someotherfeed.com/rss.xml', :supplied_url => 'http://someotherfeed.com/rss.xml', :max_days_before_nagging => 7)
  end
  
  describe "and the 'all' keyword" do
    before(:each) do
      @message = 'remove all'
    end
    
    it "should remove all messages for the requesting twitter name" do
      user_id = @acct1.id
      MessageProcessor.process_incoming_message(@message, @acct1.username)
      Feed.find_all_by_twitter_user_id(user_id).should be_empty
    end
    
    it "should remove the user if the user exists" do
      username = @acct1.username
      MessageProcessor.process_incoming_message(@message, username)
      TwitterUser.find_all_by_username(username).should be_empty
    end
    
  end
  
  describe "and a well-formed URL" do

    it "should delete any feeds for that user that are an exact match on the feed ID" do
      message = "remove http://foo.com/rss.xml"
      @acct1.feeds.size.should == 1
      MessageProcessor.process_incoming_message(message, @acct1.username)
      @acct1.feeds.size.should == 0
    end
    
    it "should not delete any feeds for other users that match the feed URL" do
      message = "remove http://foo.com/rss.xml"
      @acct2.feeds.size.should == 3
      MessageProcessor.process_incoming_message(message, @acct1.username)
      @acct2.feeds.size.should == 3
    end
    
  end
  
  describe "and a valid URL but missing the http prefix" do
    it "should delete any feeds for that user that are an exact match on the feed ID" do
      message = "remove foo.com/rss.xml"
      @acct1.feeds.size.should == 1
      MessageProcessor.process_incoming_message(message, @acct1.username)
      @acct1.feeds.size.should == 0
    end
    
    it "should not delete any feeds for other users that match the feed URL" do
      message = "remove foo.com/rss.xml"
      @acct2.feeds.size.should == 3
      MessageProcessor.process_incoming_message(message, @acct1.username)
      @acct2.feeds.size.should == 3
    end
  end
  
  describe "and a URL that doesn't match any of the feeds for that user" do
    it "should send a reply message" do
      
    end
    
  end
  
  describe "and a domain only that matches one or more feeds for that user" do
  end
end

describe "A message with the 'all' keyword but not the 'remove' keyword" do
end

describe "A message without any keywords but with a new url for that user" do
  it "should "
end

describe "A message without any keywords but with a url that is already present for that user" do
end

describe "A message with no keywords and no url" do
end

