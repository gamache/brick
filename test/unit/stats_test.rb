require 'test_helper'

class StatsTest < ActiveSupport::TestCase
  test 'Stats.for_season(2008)' do
    s = Season.new(:year => 2008)
    s.import_scores_dir('data/scores/2008')

    st = Stats.for_season(2008)
    assert st
    assert st.is_a?(Stats)
    assert st.is_a?(Hash)

    assert st.has_key?(:overall)
    ov = st[:overall]
    assert_equal 8576, ov[:warps]
    assert_equal 29,   ov[:nights]
    assert_equal 254,  ov[:games]
    assert_equal 254,  ov[:wins]
    assert_equal 0,    ov[:gold_stars]
    assert_equal 56,   ov[:come_ons]
    assert_equal 46,   ov[:cfbs]
    assert_equal 51,   ov[:wimps]

    assert st.has_key?('albatross')
    alb = st['albatross']
    assert_equal 654,         alb[:warps]
    assert_equal 167,         alb[:games]
    assert_equal 23,          alb[:nights]
    assert_equal 26,          alb[:wins]
  end
end

