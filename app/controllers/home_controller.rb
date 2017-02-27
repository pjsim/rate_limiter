class HomeController < ApplicationController
  def index
    response = RequestHandler.new request.remote_ip
    respond_to do |format|
      format.html { render status: response.status, plain: response.text }
    end
  end
end
