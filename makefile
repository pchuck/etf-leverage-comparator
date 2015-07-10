# etf-leverage-comparator
#
# Long-Term Leveraged ETF PErformance
#   an analysis of theoretical simulated vs actual performance
#

# tmuxinator an R dev environment
create_env:
	tmuxinator start r-financial

RMD=leveraged_etf_analysis
render:
	Rscript -e "rmarkdown::render('$(RMD).Rmd', 'html_document', '$(RMD).html'); browseURL('$(RMD).html')"

RTEST=unit_tests
test:
	Rscript -e "rmarkdown::render('$(RTEST).Rmd', 'html_document', '$(RTEST).html'); browseURL('$(RTEST).html')"

# remove generated files
clean:
	rm -f *.html *.md
	rm -rf *_figure/
	rm -rf *_cache/

