# Solo Docs

Consolidated repo for building and deploying Solo docs. 

# Deprecation notice:
- Gloo docs are now managed in the [Gloo Repo](https://github.com/solo-io/gloo/)
  - hosted at docs.solo.io/gloo/latest/
- Other products' docs will soon move to their own repos.

# Building

To build any of these docs sites locally:
* Clone the repo
* Install `hugo` (currently the CI build uses Hugo 0.54)
* Navigate to the desired product directory and run `make serve-site`. 

This will build the site and host it by default on `localhost:1313`.

# Contributing

We welcome contributions to the docs. Please test changes locally, and then open a pull request on this repo. The 
pull request must be reviewed and approved by a member of Solo. 

# Version management and publishing. 

Currently, this repo contains the consolidated docs for the latest versions of Gloo and Sqoop. When a PR merges into master, the docs are automatically deployed to `gloo.solo.io` and `sqoop.solo.io`. 
