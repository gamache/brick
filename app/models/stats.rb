require 'pp'
class Stats < Hash

  ## Stats.new returns a Stats object (hash), with sane default values.
  class << self; alias_method :orig_new, :new end
  def self.new
    self.orig_new do |h,k|
      h[k] = Hash[:warps => 0,
                  :games => 0,
                  :nights => 0,
                  :nights_won => 0,
                  :high_night => 0,
                  :wins => 0,
                  :cfbs => 0,
                  :come_ons => 0,
                  :wimps => 0,
                  :mystery_factors => 0,
                  :gold_stars => 0,

                  ## :dates holds the number of warps per date
                  ## and :nights gets computed from it
                  :dates => Hash.new(0),

                  ## :winner holds info about what this player won.
                  ## keyed by stat, value is true or false
                  :winner => Hash.new(false)
      ]
    end
  end

  ## Stats.career returns a stats hash encompassing all seasons
  ## Results are cached (as Hash, to avoid marshaling issues).
  def self.career
    stats_hash = Rails.cache.fetch('stats_overall') do
      season_stats = Season.all.map {|s| for_season(s)}
      fudged_stats = Stats.new.apply_fudges!(Fudge.where(:season => nil).all)
      stats = season_stats + [fudged_stats]
      overall_stats = merge_stats(stats)
      Hash[overall_stats]
    end
    Stats[stats_hash]
  end

  ## Stats.all returns a hash of Stats records, one :career as above and
  ## the rest keyed by season year.
  def self.all
    Season.all.
      inject({}) {|h,s| h.merge(s.year => for_season(s))}.
      merge(:overall => career)
  end

  ## Stats.for_season(season) returns a stats hash for a single season.
  ## season may be an integer or a Season object.
  ## Results are cached (as Hash, to avoid marshaling issues).
  def self.for_season(season)
    season = Season.new(:year => season) unless season.is_a?(Season)

    stats_hash = Rails.cache.fetch("stats#{season.year}") do
      stats = Stats.new
      scores = Score.where(:season => season.name).all
      fudges = Fudge.where(:season => season.name).all

      scores.each do |score|
        h = stats[score.player_id]
        h[:warps] += score.warps
        h[:wimps] += score.wimps
        h[:games] += 1
        h[:dates][score.date] += score.warps
        h[:wins]            += score.win            ? 1 : 0
        h[:cfbs]            += score.cfb            ? 1 : 0
        h[:come_ons]        += score.come_on        ? 1 : 0
        h[:mystery_factors] += score.mystery_factor ? 1 : 0
      end

      Hash[stats.
             apply_fudges!(fudges).
             calculate!.
             convert_player_ids_to_names!]
    end

    Stats[stats_hash]
  end

  def overall; self[:overall] end



  ## merge_stats merges multiple Stats objects.
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

        stat_hash[:dates].each do |date,warps|
          merged_stats[player_id][:dates][date] += warps
        end

        ## the :nights field gets destroyed during calculate.
        ## we store it as :nights_real so we can reinstate it
        merged_stats[player_id][:nights_real] =
          merged_stats[player_id][:nights]
      end
    end

    merged_stats.calculate!

    ## now restore the real night counts
    merged_stats.each do |player, stat_hash|
      #next if player == :overall
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
      [:warps, :games, :nights, :wins, :cfbs, :come_ons, :nights_won,
       :wimps, :mystery_factors, :gold_stars].each do |field|
        self[player_id][field] += f.send(field).to_i
       end
      self[player_id][:high_night] = f.high_night if
        self[player_id][:high_night].to_i < f.high_night.to_i
    end

    self
  end

  ## calculate! computes per-player and overall computed stats.
  def calculate!
    ov = self[:overall]
    ov[:high_night] = {}
    ov[:winners] = {}

    self.each do |player_id, st|
      next if player_id == :overall

      ## calculate computed stats for player
      st[:nights] += st[:dates].keys.length # if st[:nights] == 0
      st[:high_night] = st[:dates].values.max
      st[:gold_stars] = 1 if st[:nights] == 29
      st[:warps_per_game]  = 1.0 * st[:warps] / st[:games]  rescue 0
      st[:warps_per_night] = 1.0 * st[:warps] / st[:nights] rescue 0
      st[:games_per_night] = 1.0 * st[:games] / st[:nights] rescue 0
      st[:wins_per_night]  = 1.0 * st[:wins]  / st[:nights] rescue 0
      st[:wins_per_game]   = 1.0 * st[:wins]  / st[:games]  rescue 0

      ## accumulate overall stats
      [:warps, :wins, :cfbs, :come_ons,
       :wimps, :mystery_factors, :gold_stars]. each do |field|
        ov[field] += st[field]
      end
      # nights won calculation
      st[:dates].each do |date,warps|
        ov[:dates][date] += warps
        hnd = ov[:high_night][date] ||= {:players => [], :warps => 0}
        if hnd[:warps] < warps
          hnd[:players] = [player_id]
          hnd[:warps] = warps
        elsif hnd[:warps] == warps
          hnd[:players].push(player_id)
        end
      end
    end

    ## update overall computed stats
    st = self[:overall]
    ov[:games] = ov[:wins]
    ov[:nights] = ov[:dates].keys.length
    ov[:nights] = 29 if ov[:nights] == 0 ## provide sane default
    ov[:nights] = ov[:nights_real] if ov[:nights_real]
    ov[:warps_per_game]  = 1.0 * ov[:warps] / ov[:games]  rescue 0
    ov[:warps_per_night] = 1.0 * ov[:warps] / ov[:nights] rescue 0
    ov[:games_per_night] = 1.0 * ov[:games] / ov[:nights] rescue 0
    ov[:high_night].each do |date,h|
      h[:players].each {|p| self[p][:nights_won] += 1}
    end

    ## determine per-stat winners
    # fuck everyone but the top 50 OR those with 50+ warps
    # the 51 below is not a bug
    sorted_players = self.keys.sort{|a,b| self[b][:warps] <=> self[a][:warps]}
    fifty_plus = self.keys.select{|p| self[p][:warps] >= 50}
    eligible = (sorted_players[0..51] | fifty_plus).
                  inject(Hash.new(false)) {|acc,p| acc.merge(p => true)}
    [:warps, :games, :nights, :wins, :nights_won, :cfbs,
     :come_ons, :wimps, :warps_per_game, :warps_per_night,
     :games_per_night, :wins_per_game, :high_night].each do |field|
      owf = ov[:winners][field] = {:players => [], :value => 0}
      self.each do |player, st|
        next if player == :overall
        next unless eligible[player]
        if st[field].to_f > owf[:value]
          owf[:players] = [player]
          owf[:value] = st[field]
        elsif st[field] == owf[:value]
          owf[:players].push(player)
        end
      end
    end

    ## mark per-stat winners
    ov[:winners].each do |field, win|
      win[:players].each do |player|
        self[player][:winner][field] = true
      end
    end

    self
  end

  def convert_player_ids_to_names!
    ids = self.keys.select{|k| k.is_a?(Numeric)}
    player_by_id = ids.inject({}) {|acc,id| acc.merge(id => Player.find(id))}
    ids.each do |id|
      p = player_by_id[id]
      puts "no player for id #{id}" unless p
      self[p.name] = self.delete(id) if p
    end
    self[:overall][:high_night].each do |date,h|
      h[:players] = h[:players].map{|id| player_by_id[id]}
    end
    self
  end

  ## sort by warps
  def to_a
    a = []
    a.push({:player => nil, :overall => true}.merge(self[:overall]))
    (self.keys - [:overall]).
      sort {|x,y| self[y][:warps] <=> self[x][:warps]}.
      each_with_index {|k| a.push({:player => k}.merge(self[k]))}
    a
  end

end
