#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes/hugo-theme-soloio ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio; fi
	# this hash reflects the pre-docs migration state, details: https://github.com/solo-io/hugo-theme-soloio/commit/b49aed308e7c03edd2640fe52afd745d37fa0cbc
	git -C themes/hugo-theme-soloio checkout b49aed308e7c03edd2640fe52afd745d37fa0cbc
	hugo --config docs.toml

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D
