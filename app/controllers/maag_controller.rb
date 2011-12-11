class MaagController < ApplicationController
  respond_to :html, :json
  def show
    @year = params[:year]
    if @year
      @stats = Stats.for_season(@year.to_i)
      @pagetitle = "#{@year} MAAG"
    else
      @stats = Stats.career
      @pagetitle = 'Career Stats'
    end
    respond_with(@stats_array = @stats.to_a)
  end
end
