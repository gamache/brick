class PlayersController < ApplicationController
  respond_to :html, :json

  def show
    @player = Player.named(params[:id])
    render :not_found and return unless @player
    @stats = @player.stats
    @pagetitle = @player.display_name
    respond_with({:player => @player, :stats => @stats})
  end
end
