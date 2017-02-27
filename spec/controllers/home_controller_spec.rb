require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  let(:limit) { 100 }
  let(:frozen_time) { '03/02/2018 10:00AM'.to_datetime } # An exact time chosen just to ensure timing is consistent between tests

  before(:each) do
    Rails.cache.clear
    Timecop.freeze frozen_time
  end

  after(:each) do
    Rails.cache.clear
    Timecop.return
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns the text \'ok\'' do
      get :index
      expect(response.body).to eq 'ok'
    end

    it 'returns with \'ok\' with under 100 requests in under an hour' do
      (limit - 1).times do
        get :index
      end
      expect(response.body).to eq 'ok'
    end

    it 'does not return with \'ok\' with over 100 requests in under an hour' do
      (limit + 1).times do
        get :index
      end
      expect(response.body).to_not eq 'ok'
    end

    it 'returns with \'ok\' with over 100 requests in over an hour' do
      limit.times do
        get :index
      end
      Timecop.freeze frozen_time + 61.minutes
      get :index
      expect(response.body).to eq 'ok'
    end
  end
end
