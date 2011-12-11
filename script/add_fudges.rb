#!/usr/bin/env ruby
require './config/environment'

Fudge.new(:player => Player.named('triode'),
          :warps => 10,
          :season => 1999,
          :notes => 'Triode ended at 516 warps in 1999, because that'+
                    ' was his room number in Bemis').
      save!

