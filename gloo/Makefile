#----------------------------------------------------------------------------------
# Docs
#----------------------------------------------------------------------------------

site:
	if [ ! -d themes/hugo-theme-soloio ]; then git clone https://github.com/solo-io/hugo-theme-soloio themes/hugo-theme-soloio; fi
	# this hash reflects the pre-docs migration state, details: https://github.com/solo-io/hugo-theme-soloio/commit/6fd5171d2313a70695f892fdf606b4a23a3770a3
	git -C themes/hugo-theme-soloio checkout 6fd5171d2313a70695f892fdf606b4a23a3770a3
	hugo --config docs.toml
	# ensure that valid json is generated. Common cause: using yaml ">" multiline string symbols in Hugo's toml headers
	cat site/index.json | jq "." > /dev/null

.PHONY: deploy-site
deploy-site: site
	firebase deploy --only hosting:gloo-docs

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
	htmlproofer ./site/ --empty-alt-ignore  --allow-hash-href --alt-ignore "/img/Gloo-01.png" --url-ignore "/localhost/,/github.com/solo-io/solo-projects/,/developers.google.com/,/getgrav.org/,/github.com/solo-io/gloo/projects/,/developer.mozilla.org/"

# If on fedora, run
#     sudo dnf -y install gcc ruby-devel rubygems zlib-devel
# to install html-proofer deps (only works with gcc, not clang!)
install-tools:
	gem install html-proofer

.PHONY: docker-push
docker-push:
	docker build -t gcr.io/solo-test-236622/gloo-docs:dev .
	docker push gcr.io/solo-test-236622/gloo-docs:dev
