require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TwitterUser do
  before(:each) do
    @valid_attributes = {
      :username => 'mytwitteracct'
    }
  end

  it "should create a new instance given valid attributes" do
    TwitterUser.create!(@valid_attributes)
  end
end
