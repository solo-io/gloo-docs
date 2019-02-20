#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes ]; then  git clone https://github.com/matcornic/hugo-theme-learn.git themes/hugo-theme-learn; fi
	hugo --config docs.toml

.PHONY: deploy-site
deploy-site: site
	firebase deploy --only hosting:gloo-docs

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D