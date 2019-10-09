#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes/hugo-theme-soloio ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio; fi
	# this hash reflects the pre-docs migration state, details: https://github.com/solo-io/hugo-theme-soloio/commit/b49aed308e7c03edd2640fe52afd745d37fa0cbc
	git -C themes/hugo-theme-soloio checkout b49aed308e7c03edd2640fe52afd745d37fa0cbc
	hugo --config docs.toml

.PHONY: deploy-site
deploy-site: site
	firebase deploy --only hosting:supergloo-docs

.PHONY: serve-site
serve-site: site
	hugo --config docs.toml server -D

.PHONY: clean
clean:
	rm -fr ./site ./resources

# Uses https://github.com/gjtorikian/html-proofer
# Does not require running site; just make sure you generate the site and then run it
# Install with gem install html-proofer
# Another option we could use is wget: https://www.digitalocean.com/community/tutorials/how-to-find-broken-links-on-your-website-using-wget-on-debian-7
.PHONY: check-links
check-links:
	htmlproofer ./site/ --allow-hash-href --alt-ignore "/img/Gloo-01.png" --url-ignore "/localhost/,/github.com/solo-io/solo-projects/,/developers.google.com/,/getgrav.org/,/github.com/solo-io/gloo/projects/,/developer.mozilla.org/"
