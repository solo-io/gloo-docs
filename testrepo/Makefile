#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio && git --git-dir=themes/hugo-theme-soloio/.git checkout 9bd197dddd126e613785e682df01cab706d7831e; fi
	hugo --config docs.toml

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D
