
ruby '>=2.6'

source "https://rubygems.org"

# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#

# If you have any plugins, put them here!
gem 'wdm', '>= 0.1.0' if Gem.win_platform?
group :jekyll_plugins do
    gem 'jekyll-feed'
    gem 'jekyll-sitemap'
    gem 'jekyll-paginate'
    gem 'jekyll-seo-tag'
    gem 'jekyll-archives'
    gem 'kramdown'
    gem 'rouge'
end

# used in _plugins/vespa_index_generator.rb
gem 'json'
gem 'nokogiri'

# Work-around for webrick no longer included in Ruby 3.0 (https://github.com/jekyll/jekyll/issues/8523)
gem "webrick"

# Get the html-proofer to work
gem 'rake'
gem 'html-proofer'
