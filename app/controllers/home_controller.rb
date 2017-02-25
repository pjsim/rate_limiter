class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html { render plain: 'ok' }
    end
  end
end
