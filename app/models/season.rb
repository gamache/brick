class Season
  attr_reader :year
  
  def self.all
    years = Rails.cache.fetch("years") do
      ActiveRecord::Base.connection.
        select_all('SELECT season FROM scores GROUP BY season').
        values
    end
    years.map {|y| Season.new(:year => y)}
  end

  ## 'stats' is the main MAAG calculator.  Returns a hash structure 
  ## containing all fields for a MAAG. 'season' should be a four-digit
  ## year, or nil to get career stats.
  def stats;     self.class.stats(self.year)     end
  def raw_stats; self.class.raw_stats(self.year) end

  def self.stats(season=nil)
    Rails.cache.fetch("stats#{season}") do
      compute_stats!(raw_stats(season))
    end
  end

  def self.merge_raw_stats(*stats_list)
    ## make splat notation optional
    stats_list = stats_list.first if stats_list.first.is_a?(Array)

    ## accmulate total stats in the 'stats' hash
    stats = stats_list.pop
    stats_list.each do |player_stat|
      player_stat.each do |player_id, stat_hash|
        if stats[player_id]
          stat_hash.each do |field, value|
            stats[player_id][field] += value
          end
        else
          stats[player_id] = stat_hash
        end
      end
    end

    stats
  end

  def self.raw_stats(season=nil)
    Rails.cache.fetch("raw_stats#{season}") do
      if season
        stats = merge_raw_stats(Season.all.map(&:raw_stats))
        apply_fudges_to_stats!(stats, Fudge.where(:season => nil))
        return stats
      end

      scores = Score.where(:season => season)
      fudges = Fudge.where(:season => season)

      stats = Hash.new do
        {:warps => 0,
         :games => 0,
         :dates => [],  ## this will be reduced to 'nights' below
         :wins => 0,
         :cfbs => 0,
         :come_ons => 0,
         :wimps => 0,
         :mystery_factors => 0,
         :gold_stars => 0}
      end

      scores.each do |score|
        h = stats[score.player_id]
        h[:warps] += score.warps
        h[:games] += 1
        h[:dates] += score.date
        h[:wins]            += score.win            ? 1 : 0
        h[:cfbs]            += score.cfb            ? 1 : 0
        h[:come_ons]        += score.come_on        ? 1 : 0
        h[:wimps]           += score.wimp           ? 1 : 0
        h[:mystery_factors] += score.mystery_factor ? 1 : 0
      end

      apply_fudges_to_stats!(stats, fudges)

      stats
    end
  end

  def self.apply_fudges_to_stats!(stats, fudges)
    fudges.each do |fudge|
      h = stats[fudge.player_id]
      [:warps, :games, :nights, :wins, :cfbs, :come_ons, :wimps,
       :mystery_factors, :gold_stars].each do |field|
        h[field] = fudge.send(field)
      end
    end
  end

  def self.compute_stats!(stats)
    ## compute gold star, number of nights, and computed fields
    stats.each do |player_id, stat|
      stat[:gold_star] += 1 if stat[:nights] == 29
      stat[:nights] = stats.delete(:dates).length

      stat[:warps_per_game]  = stats[:warps] / stats[:games]
      stat[:warps_per_night] = stats[:warps] / stats[:nights]
      stat[:games_per_night] = stats[:games] / stats[:nights]
      stat[:wins_per_night]  = stats[:wins]  / stats[:nights]
      stat[:wins_per_game]   = stats[:wins]  / stats[:games]

      [:warps_per_game, :warps_per_night, :games_per_night].each do |f|
        stat[f] = sprintf "%.3f", stat[f]
      end
      [:wins_per_night, :wins_per_game].each do |f|
        stat[f] = sprintf "%.2f%%", stat[f]*100
      end
    end
  end

end
