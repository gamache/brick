class Player < ActiveRecord::Base
  ## Find or create a player with a given name.
  ## Forces name into canonical format (lowercase, letters/numbers only).
  def self.named(name)
    canonical_name = name.gsub(/[^a-zA-Z0-9]/, '').downcase
    p = Player.find_by_name(canonical_name)
    return p if p
    p = Player.new(:name => canonical_name, :display_name => name)
    p.save!
    p
  end
end
