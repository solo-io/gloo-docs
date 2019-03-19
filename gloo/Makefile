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

# Uses https://github.com/raviqqe/muffet
# Install with go get -u github.com/raviqqe/muffet
# Another option we could use is wget: https://www.digitalocean.com/community/tutorials/how-to-find-broken-links-on-your-website-using-wget-on-debian-7
.PHONY: check-links
check-links:
	muffet http://localhost:1313 --exclude 'gohugo.io|solo.io|localhost'