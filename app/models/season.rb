class Season
  attr_reader :year
  def name; year end

  def initialize(attrs={})
    y = attrs[:year] || attrs[:name]
    @year = y.to_i
  end

  def self.all
    years = Rails.cache.fetch("years") do
      ActiveRecord::Base.connection.
        select_all('SELECT season FROM scores GROUP BY season').
        values
    end
    years.map {|y| Season.new(:year => y)}
  end

  def stats;            Stats.for_season(self) end
  def self.stats(name); Stats.for_season(name) end

  def import_maag_tsv(maag_filename)
    File.open(maag_filename, 'r') do |maag|
      maag.each_line do |line|
        next if line[0] == '#'
        player_name, warps, games, nights, wins,
          nights_won, cfbs, high_night, come_ons = line.split(/\t/)
        player = Player.named(player_name)
        fudge = Fudge.new(
          :season => self.name,
          :player_id => player.id,
          :warps => warps,
          :games => games,
          :nights => nights,
          :wins => wins,
          :nights_won => nights_won,
          :cfbs => cfbs,
          :come_ons => come_ons,
          :notes => "Imported from season #{self.name} MAAG"
        )
        fudge.save!
      end
    end
    self
  end

  def import_scores_dir(scores_dirname)
    1.upto(31).each do |night|
      puts scores_file = "#{scores_dirname}/#{night}"
      self.import_scores_file(scores_file) if File.readable?(scores_file)
    end
  end

  def import_scores_file(scores_file, night=nil)
    if !night
      m = scores_file.match(/(\d+)$/)
      night = m[1] rescue nil
    end
    File.open(scores_file, 'r') do |scores|
      scores.each_line do |line|
        games = line.split(/\s+/)
        player = Player.named(games.shift)
        games.map(&:downcase).each do |game|
          match = game.match(/^(\d+)/)
          next unless match
          warps = match[1]
          win = !! game.match(/!/)
          cfb = !! game.match(/cfb/)
          come_on = !! game.match(/on/)
          mystery_factor = !! game.match(/mf/)
          wimps = game.gsub(/[^w]/,'').length
          s = Score.new(
            :player_id => player.id,
            :season => self.year,
            :night => night.to_i,
            :warps => warps.to_i,
            :win => win,
            :cfb => cfb,
            :come_on => come_on,
            :wimps => wimps,
            :mystery_factor => mystery_factor
          )
          puts "\n\n\n\n\n#{s.inspect}\n\n\n\n\n" if wimps > 0
          s.save!
        end
      end
    end
  end
end
