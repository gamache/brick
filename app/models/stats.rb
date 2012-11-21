require 'pp'
class Stats < Hash

  ## A Stats object contains the digested statistics for all November
  ## Games records.
  #
  ## It's a plain hash that looks like this at the top level:
  #
  # { :season => {
  #     :career => <stats hash>,
  #     1999  => <stats hash>,
  #     2000  => <stats hash>,
  #     ...
  #   },
  #   :player => {
  #     'player1' => {
  #       :career => <stats hash>,
  #       1999  => <stats hash>,
  #       2000  => <stats hash>,
  #       ...
  #     }
  #     'player2' => { ... },
  #     ...
  #   },
  #   :night => {
  #     1999 => {
  #       1 => {
  #         'player1' => <stats hash>,
  #         'player2' => <stats hash>,
  #         ...
  #       },
  #       2 => ...,     and so on for all nights
  #     },
  #     2000 => ...,  and so on for all seasons with such data
  #   }
  # }
  #
  ## Five types of statistic are being kept:
  #
  # stats[:season][:career] is the overall tally for all games.
  # stats[:season][1999] is the overall tally for the 1999 season.
  # stats[:player]['triode'][:career] is triode's career stats.
  # stats[:player]['triode'][1999] is triode's 1999 stats.
  # stats[:night][2012][1]['triode'] is triode's stats for opening
  #   night of the 2012 season.

  COLLECTED_STATS = [:warps, :games, :games_won, :cfbs, :come_ons,
                     :wimp_marks, :mystery_factors]
  COMPUTED_STATS = [:nights, :nights_won, :high_night, :gold_stars]
  STATS = COLLECTED_STATS + COMPUTED_STATS

  def initialize(set={})
    self.merge!({
      :season => {},
      :player => {},
      :night => {}
    })
    compute!(set)
  end

private

  ## Computes total statistics based on the given Scores and Fudges, or
  ## all Scores and Fudges if not specified.
  def compute!(set={})
    scores = set[:scores] || Score.all(:include => :player)
    fudges = set[:fudges] || Fudge.all(:include => :player)

    ingest_scores!(scores)
    ingest_fudges!(fudges)

    compute_stats!
    expose_failures ## FIXME omg dubious thinking ahead

    sort_seasons_by_warps!
    mark_top_winners!

    self
  end

  ## For a given player name, season, and night, returns a list of
  ## stats hashes to which a Score or Fudge should be added.
  ## Any or all of the player name, season, and night may be nil.
  def get_stats_hashes(attrs)
    player_name = attrs[:name]
    season = attrs[:season]
    night = attrs[:night]

    stats_hashes = []

    ## set up season career (overall) record
    self[:season][:career] ||= {}
    stats_hashes << self[:season][:career][player_name] ||= {}

    ## set up night record
    if night && player_name
      night_by_season = self[:night][season] ||= {}
      night_by_player = night_by_season[night] ||= {}
      stats_hashes << night_by_player[player_name] ||= {}
    end

    ## set up season record
    if season
      self[:season][season] ||= {}
      stats_hashes << self[:season][season][player_name] ||= {}
    end

    ## set up player career and player season records
    if player_name
      p = self[:player][player_name] ||= {}
      stats_hashes << p[season] ||= {} if season
      stats_hashes << p[:career] ||= {}
    end

    stats_hashes
  end

  ## Adds non-computed information about each Score to the stats.
  def ingest_scores!(scores)
    scores.each do |score|
      ## get the stats hashes to which the score must be added
      stats_hashes = get_stats_hashes(:name => score.player.name,
                                      :season => score.season,
                                      :night => score.night)


      ## and add the score to those records
      COLLECTED_STATS.each do |stat|
        value = score.send(stat)
        stats_hashes.each do |stats_hash|
          stats_hash[stat] ||= 0
          stats_hash[stat] += value.to_i
        end
      end
    end

  end

  def expose_failures
    self[:season].each do |season, stats|
      stats.each do |player, stats_hash|
        pp stats_hash unless stats_hash.is_a? Hash
      end
    end
  end

  ## Adds non-computed information about each Fudge to the stats.
  def ingest_fudges!(fudges)
    fudges.each do |fudge|
      stats_hashes = get_stats_hashes(:name => fudge.player.name,
                                      :season => fudge.season)
      COLLECTED_STATS.each do |stat|
        value = fudge.send(stat)
        stats_hashes.each do |stats_hash|
          stats_hash[stat] ||= 0
          stats_hash[stat] += value.to_i
        end
      end

    end
  end

  ## Adds computed information to the stats.
  ## FIXME something is wrong here
  def compute_stats!
    ## calculate nights, nights won, high night, and gold stars by using the
    ## self[:night] structure.
    high_night_for_player = Hash.new(0)

    self[:night].keys.each do |season|
      next if season == :career
      nights = self[:night][season].keys

      ## used for high night and gold star calculation
      nnights = nights.count
      high_night_this_season_for_player = Hash.new(0)
      nights_for_player = Hash.new(0)

      nights.each do |night|
        ## increment overall per-season and career total
        self[:season][:career][:nights] ||= 0
        self[:season][:career][:nights] += 1
        self[:season][season][:nights] ||= 0
        self[:season][season][:nights] += 1

        ## used for nights_won
        most_warps = 0
        night_winner = nil

        players = self[:night][season][night].keys
        players.each do |player|
          nights_for_player[player] += 1

          ## increment player's per-season and career total
          self[:player][player][:career][:nights] ||= 0
          self[:player][player][:career][:nights] += 1
          self[:player][player][season][:nights] ||= 0
          n = self[:player][player][season][:nights] += 1

          ## determine gold star status for the season
          if n == nnights
            self[:player][player][season][:gold_stars] = 1
          end

          ## update night winner, for nights_won
          warps = self[:night][season][night][player][:warps]
          if warps > most_warps
            most_warps = warps
            night_winner = player
          end

          ## update high night
          if high_night_for_player[player] < warps
            high_night_for_player[player] = warps
          end
          if high_night_this_season_for_player[player] < warps
            high_night_this_season_for_player[player] = warps
          end
        end

        ## increment nights_won for the night winner
        self[:player][night_winner][:career][:nights_won] ||= 0
        self[:player][night_winner][:career][:nights_won] += 1
        self[:player][night_winner][season][:nights_won] ||= 0
        self[:player][night_winner][season][:nights_won] += 1
      end # nights.each

      ## store high night per-season data
      high_night_this_season_for_player.each do |player, warps|
        self[:player][player][season][:high_night] = warps
      end
    end # seasons.each

    ## store high-night career data
    high_night_for_player.each do |player, warps|
      self[:player][player][:career][:high_night] = warps
    end
  end

  ## FIXME this part is totally fucked
  def sort_seasons_by_warps!
    self[:season].each do |season, stats|
      # stats.each {|player, st| pp season unless st.is_a? Hash}
      self[:season][season] = Hash[ stats.sort_by {|k,v| 
        -v[:warps] rescue 0
      }]
    end
  end

  ## Mark the winners of each stat in the top N stats (by warps).
  def mark_top_winners!(n=50)
    self[:season].each do |season, stats_hashes|
      ## for each stat, sort the top-N-by-warps on that stat and
      ## mark the top scores 
      top = Hash[ stats_hashes.to_a[0..n] ]
      STATS.each do |stat|
        score = nil
        top.sort_by{|k,v| -v[stat]}.each do |player, stats_hash|
          score ||= stats_hash[stat]
          break unless score == stats_hash[stat]
          stats_hash[:top_scores] ||= []
          stats_hash[:top_scores] << stat
        end
      end
    end
  end

end

__END__


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
      [:warps, :games, :nights, :wins, :cfbs, :come_ons,
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
