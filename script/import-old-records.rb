#!/usr/bin/env ruby
require './config/environment'

Season[1999].import_maag_tsv('data/maags/maag1999.tsv')
Season[2000].import_maag_tsv('data/maags/maag2000.tsv')
Season[2001].import_maag_tsv('data/maags/maag2001.tsv')
Season[2002].import_maag_tsv('data/maags/maag2002.tsv')
Season[2003].import_maag_tsv('data/maags/maag2003.tsv')
Season[2004].import_maag_tsv('data/maags/maag2004.tsv')

Season[2008].import_scores_dir('data/scores/2008')
Season[2009].import_scores_dir('data/scores/2009')
Season[2010].import_scores_dir('data/scores/2010')
Season[2011].import_scores_dir('data/scores/2011')
