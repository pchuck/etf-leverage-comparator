# etf-leverage-comparator
#
# Coursera, Developing Data Products, Final Project
# shiny application and slidify presentation
#

# tmuxinator an R dev environment
create_env:
	tmuxinator start r-sandbox

# install prerequisite packages
prereqs:
	R -e "install.packages(c('devtools', 'shiny'), repos='http://cran.us.r-project.org'); devtools::install_github('rstudio/shinyapps')"
	R -e "devtools::install_github('ramnathv/slidify'); devtools::install_github('ramnathv/slidifyLibraries');"

# render the etf comparison analysis
render:
	./R/rmdToHtml.R leveraged_etf_analysis

test:
	./R/rmdToHtml.R unit_tests

# remove generated files
clean:
	rm -f *.html *.md
	rm -rf figure/
	rm -rf cache/

