# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__) + '/../spec_helper'

describe MypageController do
  before(:each) do
    @user = user_login
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /mypage/apply_email" do
    before do
      session[:user_id] = 1
    end
    it "should be successful" do
      post :apply_email, {:applied_email => {:email => SkipFaker.email}}
      response.should be_success
      assigns[:menu].should == "manage_email"
      assigns[:user].should == @user
      AppliedEmail.find_by_id(assigns(:applied_email).id).should_not be_nil
      ActionMailer::Base.deliveries.first.body.should match(/http:\/\/test\.host\/mypage\/update_email\/.*/m)
    end
  end

  describe "POST /mypage/apply_ident_url" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    describe '新規登録の場合' do
      before do
        @url = 'http://example.com'

        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id, :url => @url)
        @openid_identifier.stub!(:url=).with(@url)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(true)
        @openid_identifiers.stub!(:build).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end

      describe '保存に成功した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(true)
          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect  }
        it { flash[:notice].should_not be_nil }
      end

      describe '保存に失敗した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { assigns[:openid_identifier].should_not be_nil }
        it { response.should render_template('mypage/_manage_openid') }
        it { flash[:notice].should be_nil }
      end
    end
    describe '更新の場合' do
      before do
        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(false)
        @openid_identifiers.stub!(:first).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end
      describe '保存に成功した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(true)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect }
        it { flash[:notice].should_not be_nil }
      end
      describe '保存に失敗した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should render_template('mypage/_manage_openid') }
        it { assigns[:openid_identifier].should_not be_nil }
      end
    end
  end

  describe "GET /mypage/apply_ident_url" do
    before do
      get :apply_ident_url
    end
    it { response.should redirect_to(:action => :index)}
  end
end

describe MypageController, 'POST #update_profile' do
  before do
    @profile = stub_model(UserProfile)
    @profile.stub!(:attributes_for_registration)
    @profile.stub!(:save!)
    @user = user_login
    @user.stub!(:save!)
    @user.stub!(:user_profile).and_return(@profile)
    @user.stub!(:within_time_limit_of_activation_token?)
  end
  describe '保存に成功する場合' do
    before do
      @profile.should_receive(:attributes_for_registration)
      @profile.should_receive(:save!)

      @user.should_receive(:attributes=).with(params[:user])
      @user.should_receive(:save!)
      controller.stub!(:current_user).and_return(@user)

      post :update_profile, {"new_address_2"=>"", "commit"=>"保存", "profile"=>{"birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "extension"=>"111111", "address_1"=>"1", "alma_mater"=>"あああ", "birth_day"=>"1", "gender_type"=>"1", "self_introduction"=>"よろしく", "address_2"=>"あははははははは", "introduction"=>"", "section"=>"TC", "hometown"=>"1"}, "write_profile"=>"true", "action"=>"update_profile", "new_alma_mater"=>"", "controller"=>"mypage", "new_section"=>"", "hobbies"=>["習いごと", "語学", "マンガ", "美容"]}
    end

    it {response.should be_redirect}
    it {assigns[:user].should_not be_nil}
    it {assigns[:profile].should_not be_nil}
    it {assigns[:error_msg].should be_nil}
  end
  describe '保存に失敗する場合' do
    before do
      @user.should_receive(:save!).and_raise(mock_record_invalid)
      controller.stub!(:current_user).and_return(@user)
      post :update_profile
    end
    it {response.should be_success}
    it {response.should render_template('mypage/_manage_profile')}
  end
end

describe MypageController, "POST /apply_password" do
  before do
    INITIAL_SETTINGS['login_mode'] = 'password'

    @user = user_login
    @user.should_receive(:change_password)
    @user.should_receive(:errors).and_return([])

    post :apply_password
  end
  it { response.should redirect_to(:action => :manage, :menu => :manage_password) }
end

describe MypageController, "GET /antenna_list" do
  before do
    user_login
    @result_text = 'result_text'
    controller.should_receive(:current_user_antennas_as_json).and_return(@result_text)
    get :antenna_list
  end
  it { response.should include_text(@result_text) }
end

describe MypageController, "#unify_feed_form" do
  before do
    @channel = mock('channel')
    @items = (1..5).map{|i| mock("item#{i}") }
    @feed = mock('feed', :channel => @channel, :items => @items)
  end
  describe "feedがRSS:Rssの場合" do
    before do
      @feed.stub!(:is_a?).with(RSS::Rss).and_return(true)
      @title = "title"
      @limit = 1

      @channel.stub!(:title=)
    end
    it "titleが設定されること" do
      @channel.should_receive(:title=).with(@title)
      controller.send(:unify_feed_form, @feed, @title)
    end
    it "limit以下のアイテム数になること" do
      feed = controller.send(:unify_feed_form, @feed, @title, @limit)
      feed.items.size.should == @limit
    end
  end
  describe "feedがRSS::Atomの場合" do
    before do
      @feed.stub!(:is_a?).with(RSS::Rss).and_return(false)
    end
    describe "Atomが利用できるライブラリのバージョンの場合" do
      before do
        @feed.stub!(:is_a?).with(RSS::Atom::Feed).and_return(true)
      end
      it "AtomからRss2.0に変換されること" do
        @feed.should_receive(:to_rss).with("2.0")
        controller.send(:unify_feed_form, @feed)
      end
    end
    describe "Atomが利用でいないライブラリのバージョンの場合" do
      before do
        @feed.stub!(:is_a?).and_raise(NameError.new("uninitialized constant RSS::Atom", "RSS::Atom::Feed"))
      end
      it "ログにエラーが表示されること" do
        controller.logger.should_receive(:error).with("[Error] Rubyのライブラリが古いためAtom形式を変換できませんでした。")
        controller.send(:unify_feed_form, @feed)
      end
      it "nilが返されること" do
        controller.send(:unify_feed_form, @feed).should be_nil
      end
    end
  end
end
