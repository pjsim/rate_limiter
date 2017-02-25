require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns the text \'ok\'' do
      get :index
      expect(response.body).to eq 'ok'
    end
  end
end
