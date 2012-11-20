class Score < ActiveRecord::Base
  belongs_to :player
  def date
    "#{self.season}-11-#{self.night}"
  end

  ## These methods are here so that Scores can be ingested into
  ## Stats more easily.  They represent increments to a total count.
  def games_won
    self.win ? 1 : 0
  end
  def cfbs
    self.cfb ? 1 : 0
  end
  def wimp_marks
    self.wimps
  end
  def come_ons
    self.come_on ? 1 : 0
  end
  def mystery_factors
    self.mystery_factor ? 1 : 0
  end
  def games; 1 end
end
