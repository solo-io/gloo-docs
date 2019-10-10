#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes/hugo-theme-soloio ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio; fi
	# this hash reflects the pre-docs migration state, details: https://github.com/solo-io/hugo-theme-soloio/commit/6fd5171d2313a70695f892fdf606b4a23a3770a3
	git -C themes/hugo-theme-soloio checkout 6fd5171d2313a70695f892fdf606b4a23a3770a3
	hugo --config docs.toml

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D
