require 'pp'
class Stats < Hash

  ## A Stats object contains the digested statistics for all November
  ## Games records.
  #
  ## It's a plain hash that looks like this at the top level:
  #
  # { :overall => {
  #     :career => <stats hash>,
  #     1999    => <stats hash>,
  #     2000    => <stats hash>,
  #     ...
  #   },
  #   :season => {
  #     :career => {
  #       'player1' => <stats hash>,
  #       'player2' => <stats hash>,
  #       ...
  #     },
  #     1999  => { ... },
  #     2000  => { ... },
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
  # stats[:overall][:career] is the overall sum of all November Games records.
  # stats[:overall][1999] is the overall sum of November Games 1999.
  # stats[:season][:career] is the career MAAG, sorted by warps (descending).
  # stats[:season][2010] is the November Games 2010 MAAG.
  # stats[:player]['triode'][:career] is Triode's career totals.
  # stats[:player]['77k'][1999] is 77K's 1999 totals.
  # stats[:night][2012][1]['triode'] is triode's stats for opening night 2012.

  COLLECTED_STATS = [:warps, :games, :games_won, :cfbs, :come_ons,
                     :wimp_marks, :mystery_factors]
  COMPUTED_STATS = [:nights, :nights_won, :high_night, :gold_stars]
  STATS = COLLECTED_STATS + COMPUTED_STATS

  def initialize(set={})
    self.merge!({
      :overall => {},
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

    sort_seasons_by_warps!
    mark_top_winners!

    self
  end

  ## For a given player name, season, and night, returns a list of
  ## stats hashes to which a Score or Fudge should be added.
  ## Any or all of the player name, season, and night may be nil,
  ## which means the number of stats hashes returned may vary.
  def get_stats_hashes(attrs)
    player_name = attrs[:name]
    season = attrs[:season]
    night = attrs[:night]

    stats_hashes = []

    ## career record for this player
    self[:season][:career] ||= {}
    stats_hashes << self[:season][:career][player_name] ||= {}

    ## season record for this player
    if season
      self[:season][season] ||= {}
      stats_hashes << self[:season][season][player_name] ||= {}
    end

    ## night record for this player
    if night && player_name
      night_by_season = self[:night][season] ||= {}
      night_by_player = night_by_season[night] ||= {}
      stats_hashes << night_by_player[player_name] ||= {}
    end

    ## player career and player season records
    if player_name
      p = self[:player][player_name] ||= {}
      stats_hashes << p[:career] ||= {}
      stats_hashes << p[season]  ||= {} if season
    end

    ## overall career and season records
    stats_hashes << self[:overall][:career] ||= {}
    stats_hashes << self[:overall][season]  ||= {} if season

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


  ## Adds non-computed information about each Fudge to the stats.
  def ingest_fudges!(fudges)
    fudges.each do |fudge|
      stats_hashes = get_stats_hashes(:name => fudge.player.name,
                                      :season => fudge.season)
      STATS.each do |stat|
        value = fudge.send(stat)
        stats_hashes.each do |stats_hash|
          stats_hash[stat] ||= 0
          stats_hash[stat] += value.to_i
        end
      end
    end
  end


  ## Adds computed information to the stats.
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
        self[:overall][:career][:nights] ||= 0
        self[:overall][:career][:nights] += 1
        self[:overall][season][:nights] ||= 0
        self[:overall][season][:nights] += 1

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


  def sort_seasons_by_warps!
    self[:season].each do |season, stats|
      stats.each {|player, st| 
        unless st.is_a? Hash
          pp player
          pp st
          pp season
        end
      }
      self[:season][season] = Hash[ stats.sort_by {|k,v|
        -v[:warps].to_i
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
        top.sort_by{|k,v| -v[stat].to_f}.each do |player, stats_hash|
          score ||= stats_hash[stat]
          break unless score == stats_hash[stat]
          break unless score.to_f > 0 # don't mark scores of 0 as winning shit
          stats_hash[:top_scores] ||= []
          stats_hash[:top_scores] << stat
        end
      end
    end
  end

end

