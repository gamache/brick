class MaagController < ApplicationController
  respond_to :html, :json
  def show
    @year = params[:year]
    #all_stats = Rails.cache.fetch("stats#{@year}") { Stats.new }
    all_stats = Stats.new
    if @year
      @stats = all_stats[:season][@year.to_i]
      @pagetitle = "#{@year} MAAG"
    else
      @stats = all_stats[:season][:career]
      @pagetitle = 'Career Stats'
    end
    respond_with(@stats_array = @stats.to_a)
  end
end
