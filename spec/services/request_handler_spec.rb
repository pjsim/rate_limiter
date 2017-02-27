require 'rails_helper'

RSpec.describe RequestHandler do
  let(:limit) { 100 }
  let(:frozen_time) { '03/02/2018 10:00AM'.to_datetime } # An exact time chosen just to ensure timing is consistent between tests
  let(:first_ip) { '1.2.3.4' }
  let(:second_ip) { '1.2.3.5' }

  before(:each) do
    Rails.cache.clear
    Timecop.freeze frozen_time
  end

  after(:each) do
    Rails.cache.clear
    Timecop.return
  end

  describe 'handle requests being made in under an hour' do
    context 'requests are below throttle limit' do
      it 'returns a status of 200' do
        limit.times do
          response = RequestHandler.new(first_ip)
          expect(response.status).to eq(200)
        end
      end
      it 'returns the text \'ok\'' do
        limit.times do
          response = RequestHandler.new(first_ip)
          expect(response.text).to eq('ok')
        end
      end
    end
    context 'requests are above throttle limit' do
      it 'returns a status of 429' do
        (limit * 2).times do |i|
          response = RequestHandler.new(first_ip)
          expect(response.status).to eq(429) if i > limit
        end
      end
      it 'returns the text saying the limited has exceeded and the seconds remaining till it expires' do
        (limit * 2).times do |i|
          response = RequestHandler.new(first_ip)
          expect(response.text).to eq('Rate limit exceeded. Try again in 3600 seconds') if i > limit
        end
      end
      it 'it returns an accurate time in seconds till expiry' do
        (limit * 2).times do |i|
          response = RequestHandler.new(first_ip)
          Timecop.freeze(frozen_time + 1.hour - 90.seconds)
          expect(response.text).to eq('Rate limit exceeded. Try again in 90 seconds') if i > limit
        end
      end
    end
  end

  describe 'handle requests being made in over an hour' do
    context 'requests are below throttle limit' do
      before(:each) do
        (limit - 1).times do
          RequestHandler.new(first_ip)
        end
        Timecop.freeze frozen_time + 61.minutes
      end
      it 'returns a status of 200' do
        response = RequestHandler.new(first_ip)
        expect(response.status).to eq(200)
      end
      it 'returns the text \'ok\'' do
        response = RequestHandler.new(first_ip)
        expect(response.text).to eq('ok')
      end
    end
    context 'requests are above throttle limit' do
      before(:each) do
        (limit * 2).times do |i|
          RequestHandler.new(first_ip)
        end
        Timecop.freeze frozen_time + 61.minutes
      end
      it 'returns a status of 200' do
        response = RequestHandler.new(first_ip)
        expect(response.status).to eq(200)
      end
      it 'returns the text \'ok\'' do
        response = RequestHandler.new(first_ip)
        expect(response.text).to eq('ok')
      end
    end
  end

  describe 'handle different IP requests being made' do
    before(:each) do
      (limit * 2).times do |i|
        RequestHandler.new(first_ip)
      end
    end
    context 'the same IP tries to make requests over the limit' do
      it 'returns a status of 429' do
        response = RequestHandler.new(first_ip)
        expect(response.status).to eq(429)
      end
    end
    context 'a different IP tries to make requests over the limit' do
      it 'returns a status of 200' do
        response = RequestHandler.new(second_ip)
        expect(response.status).to eq(200)
      end
    end
  end
end
