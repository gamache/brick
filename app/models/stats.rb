require 'pp'
class Stats < Hash

  ## Stats.all returns a stats hash encompassing all seasons
  def self.all
    season_stats = Season.all.map {|s| for_season(s)}
    fudged_stats = Stats.new.apply_fudges!(Fudge.where(:season => nil).all)
    stats = season_stats + [fudged_stats]
    overall_stats = merge_stats(stats)
  end

  def self.for_season(season)
    season = Season.new(:year => season) unless season.is_a?(Season)

    stats = Stats.new
    scores = Score.where(:season => season.name).all
    fudges = Fudge.where(:season => season.name).all

    scores.each do |score|
      h = stats[score.player_id]
      h[:warps] += score.warps
      h[:wimps] += score.wimps
      h[:games] += 1
      h[:dates][score.date] += 1
      h[:wins]            += score.win            ? 1 : 0
      h[:cfbs]            += score.cfb            ? 1 : 0
      h[:come_ons]        += score.come_on        ? 1 : 0
      h[:mystery_factors] += score.mystery_factor ? 1 : 0
    end

    stats.
      apply_fudges!(fudges).
      calculate!.
      convert_player_ids_to_names!
  end

  def overall; self[:overall] end



  ## Stats.new returns a Stats object (hash), with sane default values.
  class << self; alias_method :orig_new, :new; end
  def self.new
    self.orig_new do |h,k|
      h[k] = Hash[:warps => 0,
                  :games => 0,
                  :nights => 0,

                  ## :dates holds the number of player-games per date
                  ## and :nights gets computed from it
                  :dates => Hash.new(0),

                  :wins => 0,
                  :cfbs => 0,
                  :come_ons => 0,
                  :wimps => 0,
                  :mystery_factors => 0,
                  :gold_stars => 0]
    end
  end

  ## merge_stats merges multiple Stats objects.  calculate! should be 
  ## run on the resulting Stats object.
  def self.merge_stats(*stats_list)
    ## make splat notation optional
    stats_list = stats_list.first if stats_list.first.is_a?(Array)

    ## accumulate stats
    merged_stats = Stats.new
    stats_list.each do |stats|
      stats.each do |player_id, stat_hash|
        [:warps, :games, :nights, :wins, :cfbs, 
         :come_ons, :wimps, :mystery_factors, :gold_stars].each do |k|
          merged_stats[player_id][k] += stat_hash[k]
        end

        stat_hash[:dates].each do |date,games|
          merged_stats[player_id][:dates][date] += games
        end

        ## the :nights field gets destroyed during calculate,
        ## so we store it as :nights_real so we can reinstate it
        merged_stats[player_id][:nights_real] = 
          merged_stats[player_id][:nights]
      end
    end

    merged_stats.calculate!

    ## now restore the real night counts
    merged_stats.each do |player, stat_hash|
      next if player == :overall
      stat_hash[:nights] = stat_hash.delete(:nights_real)
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
        self[player_id][field] += f.send(field).to_i
       end
    end

    self
  end

  ## calculate! computes per-player and overall computed stats.
  ## Non-integer computed stats are also returned as strings.
  def calculate!
    ov = self[:overall]

    self.each do |player_id, st|
      next if player_id == :overall

      ## accumulate overall stats
      [:warps, :wins, :cfbs, :come_ons,
       :wimps, :mystery_factors, :gold_stars]. each do |field|
        ov[field] += st[field]
      end
      st[:dates].each {|date,games| ov[:dates][date] += games}

      ## calculate computed stats for player
      st[:nights] += st[:dates].keys.length # if st[:nights] == 0
      st[:gold_stars] = 1 if st[:nights] == 29
      st[:warps_per_game]  = 1.0 * st[:warps] / st[:games]  rescue 0
      st[:warps_per_night] = 1.0 * st[:warps] / st[:nights] rescue 0
      st[:games_per_night] = 1.0 * st[:games] / st[:nights] rescue 0
      st[:wins_per_night]  = 1.0 * st[:wins]  / st[:nights] rescue 0
      st[:wins_per_game]   = 1.0 * st[:wins]  / st[:games]  rescue 0

      ## format non-integer stats
      [:warps_per_game,
       :warps_per_night,
       :games_per_night,
       :wins_per_night,
       :wins_per_game].each do |f|
        st["#{f}_str".to_sym] = sprintf "%.3f", st[f]
      end
      # [:wins_per_night, :wins_per_game].each do |f|
      #   st["#{f}_str".to_sym] = sprintf "%.2f%%", st[f]*100
      # end
    end

    ## update overall computed stats
    st = self[:overall]
    st[:games] = st[:wins]
    st[:nights] = st[:dates].keys.length
    st[:nights] = 29 if st[:nights] == 0 ## provide sane default
    st[:warps_per_game]  = 1.0 * st[:warps] / st[:games]  rescue 0
    st[:warps_per_night] = 1.0 * st[:warps] / st[:nights] rescue 0
    st[:games_per_night] = 1.0 * st[:games] / st[:nights] rescue 0
    [:warps_per_game, :warps_per_night, :games_per_night].each do |f|
      st["#{f}_str".to_sym] = sprintf "%.3f", st[f]
    end

    self
  end

  def convert_player_ids_to_names!
    ids = self.keys.select{|k| k.is_a?(Numeric)}
    ids.each do |id|
      p = Player.find(id)
      self[p.name] = self.delete(id)
    end
    self
  end

  ## sort by warps
  def to_a
    a = []
    a.push({:player => nil, :overall => true}.merge(self[:overall]))
    (self.keys - [:overall]).
      sort {|x,y| self[y][:warps] <=> self[x][:warps]}.
      each {|k| a.push({:player => k}.merge(self[k]))}
    a
  end

end
