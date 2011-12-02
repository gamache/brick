class Stats < Hash

  ## Stats.all returns a stats hash encompassing all seasons
  def self.all
    season_stats = Season.all.map {|s| for_season(s)}
    overall_stats = merge_stats!(season_stats)
    overall_stats.apply_fudges!(Fudge.where(:season => nil))
    overall_stats.calculate!
  end

  def self.for_season(season)
    season = Season.new(:year => season) unless season.is_a?(Season)

    stats = Stats.new
    puts stats.class
    scores = Score.where(:season => season.name).all
    fudges = Fudge.where(:season => season.name).all

    scores.each do |score|
      h = stats[score.player_id]
      h[:warps] += score.warps
      h[:games] += 1
      h[:dates][score.date] += 1
      h[:wins]            += score.win            ? 1 : 0
      h[:cfbs]            += score.cfb            ? 1 : 0
      h[:come_ons]        += score.come_on        ? 1 : 0
      h[:wimps]           += score.wimp           ? 1 : 0
      h[:mystery_factors] += score.mystery_factor ? 1 : 0
    end

    stats.apply_fudges!(fudges)

    stats.calculate!

    stats
  end



  ## Stats.new returns a Stats object (hash), with sane default values.
  class << self; alias_method :orig_new, :new; end
  def self.new
    self.orig_new do |h,k|
      h[k] = Hash[:warps => 0,
              :games => 0,
              :nights => 0,

              ## :dates holds the number of player-games per date
              ## and :nights gets computed from it, for players
              :dates => Hash.new(0),  ## this will be reduced to 'nights' below

              :wins => 0,
              :cfbs => 0,
              :come_ons => 0,
              :wimps => 0,
              :mystery_factors => 0,
              :gold_stars => 0]
    end
  end

  ## merge_stats! merges multiple Stats objects, destroying at least
  ## one in the process.  calculate! should be run on the resulting
  ## Stats object.
  def self.merge_stats!(*stats_list)
    ## make splat notation optional
    stats_list = stats_list.first if stats_list.first.is_a?(Array)

    ## accumulate stats
    merged_stats = stats_list.pop
    stats_list.each do |stats|
      stats.each do |player_id, stat_hash|
        stat_hash.each {|k,v| merged_stats[player_id][k] += v}
      end
    end

    merged_stats
  end

  ## apply_fudges! incorporates the given fudge values into stats.
  def apply_fudges!(*fudges)
    ## make splat notation optional
    fudges = fudges.first if fudges.first.is_a?(Array)

    fudges.each do |f|
      player_id = f.player_id || :overall
      [:warps, :games, :nights, :wins, :cfbs, :come_ons,
       :wimps, :mystery_factors, :gold_stars].each do |field|
        self[player_id][field] += f.send(field)
       end
    end

    self
  end

  ## calculate! computes per-player and overall computed stats.
  ## Non-integer computed stats are also returned as strings.
  def calculate!
    _ = self[:overall] # we must create this entry before iterating
                       # on our own keys, otherwise ruby gets confused

    self.each do |player_id, st|
      ## update overall stats
      [:warps, :cfbs, :come_ons, :wimps, :mystery_factors, :gold_stars].
        each {|f| self[:overall][f] += st[f] }
      self[:overall][:games] += st[:wins]
      st[:dates].each{|k,v| self[:overall][:dates][k] += v}

      ## calculate computed stats for player
      st[:nights] = st[:dates].keys.length
      st[:gold_stars] = 1 if st[:nights] == 29
      st[:warps_per_game]  = st[:warps] / st[:games]  rescue 0
      st[:warps_per_night] = st[:warps] / st[:nights] rescue 0
      st[:games_per_night] = st[:games] / st[:nights] rescue 0
      st[:wins_per_night]  = st[:wins]  / st[:nights] rescue 0
      st[:wins_per_game]   = st[:wins]  / st[:games]  rescue 0

      ## format non-integer stats
      [:warps_per_game, :warps_per_night, :games_per_night].each do |f|
        st["#{f}_str".to_sym] = sprintf "%.3f", st[f]
      end
      [:wins_per_night, :wins_per_game].each do |f|
        st["#{f}_str".to_sym] = sprintf "%.2f%%", st[f]*100
      end
    end

    ## update overall computed stats
    st = self[:overall]
    st[:nights] = st[:dates].keys.length
    st[:warps_per_game]  = st[:warps] / st[:games]  rescue 0
    st[:warps_per_night] = st[:warps] / st[:nights] rescue 0
    st[:games_per_night] = st[:games] / st[:nights] rescue 0
    [:warps_per_game, :warps_per_night, :games_per_night].each do |f|
      st["#{f}_str".to_sym] = sprintf "%.3f", st[f]
    end

    self
  end

end
