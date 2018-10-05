class LocalesController < ApplicationController
  http_basic_authenticate_with :name => 'gamer', :password => 'riverside'

  def show
    @pagetitle = 'Locale'
    @current_locale = Locale.last || Locale.new
    respond_to do |format|
      format.html {}
      format.json {render :json => @current_locale}
    end
  end

  def create
    locale_params = params[:locale]
    password = locale_params.delete(:password)
    @locale = Locale.new(
      place: locale_params[:place],
      phone: locale_params[:phone],
      other: locale_params[:other],
    )

    if password == '11111'
      @locale.save!
      flash[:notice] = 'Locale updated successfully.'
      redirect_to locale_path
    else
      flash[:error] = 'Password is not correct.'
      @current_locale = Locale.last || Locale.new
      render :show, :status => :unprocessable_entity
    end
  end
end
