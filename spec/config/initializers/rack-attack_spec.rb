require 'rails_helper'

describe Rack::Attack do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  let(:limit) { 100 }
  let(:frozen_time) { '03/02/2018 10:00AM'.to_datetime }
  let(:test_path) { 'home/index' }

  before(:each) do
    Timecop.freeze frozen_time
  end

  after(:each) do
    Timecop.return
  end

  describe 'throttle IPs requesting above the limit' do
    context 'requests are below throttle limit' do
      it 'returns a status of 200' do
        limit.times do
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.4'
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'requests are above throttle limit' do
      it 'returns a status of 429' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.5'
          expect(last_response.status).to eq(429) if i > limit
        end
      end
    end
  end

  describe 'throttle IPs only until the period expires on them' do
    context 'less than 100 request are made in an hour' do
      it 'returns a status of 200' do
        limit.times do
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.6'
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'less than 100 request are made in over an hour' do
      it 'returns a status of 200' do
        limit.times do
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.7'
          Timecop.freeze frozen_time + 1.hour
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'more than 100 request are made in an hour' do
      it 'returns a status of 429' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.8'
          expect(last_response.status).to eq(429) if i > limit
        end
      end
    end

    context 'more than 100 request are made in over an hour' do
      it 'returns a status of 200' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.9'
        end
        Timecop.freeze frozen_time + 1.hour
        get test_path, {}, 'REMOTE_ADDR' => '1.2.3.9'
        expect(last_response.status).to eq(200)
      end
    end
  end

  describe 'throttle works on individual IPs only' do
    context 'the same IP tries to make requests over the limit' do
      it 'returns a status of 429' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.10'
        end
        get test_path, {}, 'REMOTE_ADDR' => '1.2.3.10'
        expect(last_response.status).to eq(429)
      end
    end

    context 'a different IP tries to make requests over the limit' do
      it 'returns a status of 200' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.11'
        end
        get test_path, {}, 'REMOTE_ADDR' => '1.2.3.12'
        expect(last_response.status).to eq(200)
      end
    end
  end

  describe 'going over the limit will display time until the throttle expires' do
    context 'an IP is not being throttled' do
      it 'displays text \'ok\'' do
        get test_path, {}, 'REMOTE_ADDR' => '1.2.3.13'
        expect(last_response.body).to eq('ok')
      end
    end

    context 'an IP is throttled and makes a request before it\'s period expires' do
      it 'displays text \'Rate limit exceeded\' and the seconds left till the expiry ends' do
        (limit * 2).times do |i|
          get test_path, {}, 'REMOTE_ADDR' => '1.2.3.14'
        end
        Timecop.freeze(frozen_time + 1.hour - 90.seconds)
        get test_path, {}, 'REMOTE_ADDR' => '1.2.3.14'
        expect(last_response.body).to eq('Rate limit exceeded. Try again in 90 seconds}')
      end
    end
  end
end
