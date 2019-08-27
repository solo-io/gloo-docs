#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio && git --git-dir=themes/hugo-theme-soloio/.git checkout 1f51653dee82a0d33a96add6a0e7fccc2ad08d6c; fi
	hugo --config docs.toml

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D
