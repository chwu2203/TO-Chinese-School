require 'spec_helper'

describe User do
  fixtures :users

  before(:each) do
    @valid_user_attributes = {
      :username => random_string(8),
      :password => random_string(10),
      :person => Person.new
    }
    @user = User.new
  end
  
  it 'should be invalid without a username' do
    @user.attributes = @valid_user_attributes.except(:username)
    @user.should_not be_valid
    @user.username = random_string 8
    @user.should be_valid
  end

  it 'should be invalid without a password' do
    @user.attributes = @valid_user_attributes.except(:password)
    @user.should_not be_valid
    @user.password = random_string 12
    @user.should be_valid
  end

  it 'should be invalid with a blank password' do
    @user.attributes = @valid_user_attributes.except(:password)
    @user.password = ''
    @user.should_not be_valid
    @user.password = random_string 12
    @user.should be_valid
  end

  it 'should be invalid with a password shorter than 6 characters' do
    @user.attributes = @valid_user_attributes.except(:password)
    @user.password = random_string 5
    @user.should_not be_valid
    @user.password = random_string 6
    @user.should be_valid
  end
  
  it 'should be invalid without a person' do
    @user.attributes = @valid_user_attributes.except(:person)
    @user.should_not be_valid
    @user.person = Person.new
    @user.should be_valid
  end

  it 'should be invalid with a username already taken' do
    @user.attributes = @valid_user_attributes.except(:username)
    @user.username = users(:one).username
    @user.should_not be_valid
    @user.username = 'username_not_used_yet'
    @user.should be_valid
  end
  
  it 'should hash password using prescribed formula' do
    password = random_string 10
    salt = random_string 6
    expected_hash = Digest::SHA256.hexdigest(password + salt)
    User.hash_password(password, salt).should == expected_hash
  end

  it 'should create a new salt when setting a new password' do
    @user.expects(:create_new_salt).once
    # The following line is needed because we mock the create_new_salt but don't want the password setter to freak out
    @user.password_salt = random_string 6
    @user.password = random_string 10
  end

  it 'should hash password when setting a new password' do
    password = random_string 10
    @user.password = password
    expected_hash = User.hash_password(password, @user.password_salt)
    @user.password_hash.should == expected_hash
  end
end


describe User, 'performing authentication' do
  fixtures :users
  
  it 'should return nil if username does not exist' do
    User.authenticate('non_existing_username', 'fake_password').should be_nil
  end

  it 'should reutrn nil if password does not match' do
    User.authenticate(users(:one).username, 'not_matching_password').should be_nil
  end

  it 'should return correct user if authentication is successful' do
    User.authenticate(users(:one).username, 'test').should == users(:one)
  end
end


describe User, 'performing authorization' do
  before(:each) do
    @fake_controller_path = random_string 14
    @fake_action_name = random_string 7
    @user = User.new
  end

  it 'should return true if one of roles is authorized for access' do
    mock_not_authorized_role = Role.new
    mock_not_authorized_role.expects(:authorized?).with(@fake_controller_path, @fake_action_name).once.returns(false)
    @user.roles << mock_not_authorized_role
    mock_authorized_role = Role.new
    mock_authorized_role.expects(:authorized?).with(@fake_controller_path, @fake_action_name).once.returns(true)
    @user.roles << mock_authorized_role
    @user.authorized?(@fake_controller_path, @fake_action_name).should be_true
  end

  it 'should return false if all roles are not authorized for access' do
    mock_not_authorized_role = Role.new
    mock_not_authorized_role.expects(:authorized?).with(@fake_controller_path, @fake_action_name).once.returns(false)
    @user.roles << mock_not_authorized_role
    @user.authorized?(@fake_controller_path, @fake_action_name).should be_false
  end
end


class UserTestAccessor < User
  public :create_new_salt
end

describe User, 'testing private methods' do
  before(:each) do
    @user = UserTestAccessor.new
  end

  it 'should create new salt using prescribed formula' do
    #
    # Just test that salt is created
    # Having trouble mocking either Kernel.rand (unable to mock by Mocha)
    # or Array.new (Rails makes additional calls to Array, which fails expectations)
    # 
    @user.password_salt.should be_nil
    @user.create_new_salt
    @user.password_salt.should_not be_nil
  end
end
