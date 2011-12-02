class Score < ActiveRecord::Base
  belongs_to :player
  def date
    "#{self.season}-11-#{self.night}"
  end
end
