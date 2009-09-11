require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Feed do
  before(:each) do
    @valid_attributes = {
      :feed_url => 'http://foo.com/rss.xml', :blog_url => 'foo.com', :max_days_before_nagging => 7
    }
  end

  it "should create a new instance given valid attributes" do
    Feed.create!(@valid_attributes)
  end
end
