class Fudge < ActiveRecord::Base
  belongs_to :player

  def games_won; wins end
  def wimp_marks; wimps end
end

