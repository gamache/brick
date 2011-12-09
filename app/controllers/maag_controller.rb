class MaagController < ApplicationController
  respond_to :html, :json
  def show
    @year = params[:year]
    @stats = @year ? Stats.for_season(@year.to_i) : Stats.career
    respond_with(@stats_array = @stats.to_a)
  end
end
